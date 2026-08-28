--!strict
-- The desk interface: Sleek, non-intrusive HUD with clean horizontal layout,
-- phone subtitle banner, [Z]/[X] verdict hotkeys, and [G] Intercom Dialogue Questioning.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))
local DeskProps = require(script.Parent:WaitForChild("DeskProps"))
local GuestRenderer = require(script.Parent:WaitForChild("GuestRenderer"))
local ShopUI = require(script.Parent:WaitForChild("ShopUI"))
local Theme = require(script.Parent:WaitForChild("Theme"))

local judge = Remotes.get("Judge")
local phoneResponse = Remotes.get("PhoneResponse")
local interrogate = Remotes.get("Interrogate")
local interrogationResponse = Remotes.get("InterrogationResponse")

local DeskUI = {}

local hudFrame: Frame
local nightLabel: TextLabel
local takingsLabel: TextLabel
local sanityFill: Frame
local sanityLabel: TextLabel
local queueLabel: TextLabel
local statusLabel: TextLabel

local phoneBannerFrame: Frame
local phoneSubtitleLabel: TextLabel

local bottomBar: Frame
local guestBriefLabel: TextLabel
local tellHighlightLabel: TextLabel
local admitButton: TextButton
local refuseButton: TextButton

local intercomModal: Frame
local intercomVisible = false
local awaiting = false

local function setPrompt(visible: boolean)
	awaiting = visible
	bottomBar.Visible = visible
	if not visible and intercomModal then
		intercomModal.Visible = false
		intercomVisible = false
	end
end

function DeskUI.send(admitted: boolean)
	if not awaiting then
		return
	end
	setPrompt(false)
	Atmosphere.playSound("thud", nil, 0.9)
	GuestRenderer.depart(admitted)
	DeskProps.clearLedger()
	judge:FireServer(admitted)
end

function DeskUI.toggleIntercom()
	if not awaiting or not intercomModal then
		return
	end
	intercomVisible = not intercomVisible
	intercomModal.Visible = intercomVisible
	Atmosphere.playSound("paper", nil, 0.5)
end

function DeskUI.ask(questionId: string)
	if intercomModal then
		intercomModal.Visible = false
		intercomVisible = false
	end
	Atmosphere.playSound("paper", nil, 0.6)
	interrogate:FireServer(questionId)
end

function DeskUI.build(gui: ScreenGui)
	-- 1. Top HUD Bar with non-colliding layout
	hudFrame = Theme.frame(gui, UDim2.new(1, -48, 0, 44), UDim2.fromOffset(24, 14))
	hudFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 20)

	nightLabel = Theme.label(hudFrame, UDim2.fromOffset(190, 44), UDim2.fromOffset(16, 12), 14)
	nightLabel.Font = Enum.Font.GothamBold
	nightLabel.TextColor3 = Theme.ink
	nightLabel.Text = "NIGHT SHIFT · 02:00 AM"

	takingsLabel = Theme.label(hudFrame, UDim2.fromOffset(140, 44), UDim2.fromOffset(210, 12), 14)
	takingsLabel.Font = Enum.Font.GothamBold
	takingsLabel.TextColor3 = Color3.fromRGB(110, 220, 140)
	takingsLabel.Text = "SAFE: $0"

	local sanityContainer = Instance.new("Frame")
	sanityContainer.Size = UDim2.fromOffset(230, 24)
	sanityContainer.Position = UDim2.new(0.5, -115, 0, 10)
	sanityContainer.BackgroundTransparency = 1
	sanityContainer.Parent = hudFrame

	local sTitle = Theme.label(sanityContainer, UDim2.fromOffset(56, 24), UDim2.new(), 12)
	sTitle.TextColor3 = Theme.inkSoft
	sTitle.Text = "SANITY:"

	local sanityBar = Instance.new("Frame")
	sanityBar.Size = UDim2.fromOffset(120, 8)
	sanityBar.Position = UDim2.fromOffset(60, 8)
	sanityBar.BackgroundColor3 = Color3.fromRGB(35, 42, 38)
	sanityBar.BorderSizePixel = 0
	sanityBar.Parent = sanityContainer

	sanityFill = Instance.new("Frame")
	sanityFill.Size = UDim2.fromScale(1, 1)
	sanityFill.BackgroundColor3 = Color3.fromRGB(80, 190, 240)
	sanityFill.BorderSizePixel = 0
	sanityFill.Parent = sanityBar

	sanityLabel =
		Theme.label(sanityContainer, UDim2.fromOffset(45, 24), UDim2.fromOffset(185, 0), 12)
	sanityLabel.TextColor3 = Theme.inkSoft
	sanityLabel.Text = "100%"

	queueLabel = Theme.label(hudFrame, UDim2.fromOffset(360, 44), UDim2.new(1, -370, 0, 12), 12)
	queueLabel.TextColor3 = Theme.inkSoft
	queueLabel.TextXAlignment = Enum.TextXAlignment.Right
	queueLabel.Text = "[E] Bell · [F] Zoom · [G] Ask · [T] Phone · [Q] UV"

	statusLabel = Theme.label(gui, UDim2.fromOffset(850, 26), UDim2.fromOffset(32, 64), 13)
	statusLabel.TextColor3 = Theme.inkSoft
	statusLabel.Text = "Desk active. Ring bell [E] to summon the next guest in queue."

	-- Dedicated Subtitle Box
	phoneBannerFrame = Theme.frame(gui, UDim2.new(1, -64, 0, 42), UDim2.new(0, 32, 1, -150))
	phoneBannerFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	phoneBannerFrame.BackgroundTransparency = 0.20
	phoneBannerFrame.Visible = false

	phoneSubtitleLabel =
		Theme.label(phoneBannerFrame, UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), 14)
	phoneSubtitleLabel.Font = Enum.Font.SpecialElite
	phoneSubtitleLabel.TextColor3 = Color3.fromRGB(245, 210, 120)
	phoneSubtitleLabel.Text = ""

	-- 2. Intercom Questioning Modal
	intercomModal = Theme.frame(gui, UDim2.fromOffset(440, 170), UDim2.new(0.5, -220, 0.5, -85))
	intercomModal.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	intercomModal.Visible = false

	local iHeader =
		Theme.label(intercomModal, UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 8), 14)
	iHeader.Font = Enum.Font.GothamBold
	iHeader.TextColor3 = Color3.fromRGB(240, 215, 130)
	iHeader.Text = "DESK INTERCOM · CHOOSE QUESTION [G]"

	local q1 = Theme.button(
		intercomModal,
		UDim2.new(1, -24, 0, 34),
		UDim2.fromOffset(12, 38),
		'1. "State your purpose of stay."'
	)
	q1.Font = Enum.Font.RobotoMono
	q1.TextSize = 12
	q1.BackgroundColor3 = Color3.fromRGB(28, 34, 42)
	q1.Activated:Connect(function()
		DeskUI.ask("purpose")
	end)

	local q2 = Theme.button(
		intercomModal,
		UDim2.new(1, -24, 0, 34),
		UDim2.fromOffset(12, 78),
		'2. "Verify your vehicle license plate."'
	)
	q2.Font = Enum.Font.RobotoMono
	q2.TextSize = 12
	q2.BackgroundColor3 = Color3.fromRGB(28, 34, 42)
	q2.Activated:Connect(function()
		DeskUI.ask("plate")
	end)

	local q3 = Theme.button(
		intercomModal,
		UDim2.new(1, -24, 0, 34),
		UDim2.fromOffset(12, 118),
		'3. "Look directly into the reception mirror."'
	)
	q3.Font = Enum.Font.RobotoMono
	q3.TextSize = 12
	q3.BackgroundColor3 = Color3.fromRGB(28, 34, 42)
	q3.Activated:Connect(function()
		DeskUI.ask("mirror")
	end)

	-- 3. Bottom Verdict Action Strip
	bottomBar = Theme.frame(gui, UDim2.new(1, -48, 0, 80), UDim2.new(0, 24, 1, -96))
	bottomBar.BackgroundColor3 = Color3.fromRGB(18, 22, 20)
	bottomBar.Visible = false

	guestBriefLabel =
		Theme.label(bottomBar, UDim2.new(0.55, -20, 0, 24), UDim2.fromOffset(16, 12), 15)
	guestBriefLabel.Font = Enum.Font.GothamBold

	tellHighlightLabel =
		Theme.label(bottomBar, UDim2.new(0.55, -20, 0, 36), UDim2.fromOffset(16, 38), 13)
	tellHighlightLabel.TextColor3 = Color3.fromRGB(240, 170, 70)
	tellHighlightLabel.TextWrapped = true

	admitButton = Theme.button(
		bottomBar,
		UDim2.fromOffset(160, 48),
		UDim2.new(1, -350, 0.5, -24),
		"ADMIT  [Z]"
	)
	admitButton.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
	admitButton.TextColor3 = Theme.ink

	refuseButton = Theme.button(
		bottomBar,
		UDim2.fromOffset(160, 48),
		UDim2.new(1, -180, 0.5, -24),
		"REFUSE  [X]"
	)
	refuseButton.BackgroundColor3 = Color3.fromRGB(160, 50, 45)
	refuseButton.TextColor3 = Theme.ink

	admitButton.Activated:Connect(function()
		DeskUI.send(true)
	end)
	refuseButton.Activated:Connect(function()
		DeskUI.send(false)
	end)

	ContextActionService:BindAction("Desk_Admit", function(_, state)
		if state == Enum.UserInputState.Begin and awaiting then
			DeskUI.send(true)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Z, Enum.KeyCode.One)

	ContextActionService:BindAction("Desk_Refuse", function(_, state)
		if state == Enum.UserInputState.Begin and awaiting then
			DeskUI.send(false)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.X, Enum.KeyCode.Two)

	ContextActionService:BindAction("Desk_IntercomKey", function(_, state)
		if state == Enum.UserInputState.Begin and awaiting then
			DeskUI.toggleIntercom()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.G)

	phoneResponse.OnClientEvent:Connect(function(data)
		if data.success then
			phoneBannerFrame.Visible = true
			phoneSubtitleLabel.Text = `☎ ROTARY PHONE: {data.message}`
			phoneSubtitleLabel.TextColor3 = if data.isOccupied
				then Color3.fromRGB(255, 60, 50)
				else Color3.fromRGB(120, 220, 140)
			task.delay(6.5, function()
				if phoneSubtitleLabel.Text == `☎ ROTARY PHONE: {data.message}` then
					phoneBannerFrame.Visible = false
				end
			end)
		end
	end)

	interrogationResponse.OnClientEvent:Connect(function(data)
		phoneBannerFrame.Visible = true
		phoneSubtitleLabel.Text = `🎙 GUEST INTERCOM: "{data.answer}"`
		phoneSubtitleLabel.TextColor3 = if data.isCreepy
			then Color3.fromRGB(255, 75, 65)
			else Color3.fromRGB(220, 225, 230)
		if data.isCreepy then
			Atmosphere.playSound("heartbeat", nil, 0.7)
		end
		task.delay(7.0, function()
			if phoneSubtitleLabel.Text == `🎙 GUEST INTERCOM: "{data.answer}"` then
				phoneBannerFrame.Visible = false
			end
		end)
	end)
end

function DeskUI.onGuest(guest)
	ShopUI.close()
	if guest.nightNumber then
		nightLabel.Text = `NIGHT {guest.nightNumber} · 02:00 AM`
	end
	guestBriefLabel.Text =
		`GUEST: {guest.name}  ·  Res #{guest.reservation}  ·  Room {guest.roomNumber or 101}`

	if guest.tell then
		tellHighlightLabel.Text = `OBSERVATION: {guest.tell}`
		tellHighlightLabel.TextColor3 = Color3.fromRGB(250, 160, 60)
	else
		tellHighlightLabel.Text =
			"Observation: Inspect ledger [F], ask question [G], call room [T], or toggle UV [Q]."
		tellHighlightLabel.TextColor3 = Theme.inkSoft
	end

	takingsLabel.Text = `SAFE: ${guest.takings or 0}`
	local sVal = guest.sanity or 100
	sanityLabel.Text = `{sVal}%`
	TweenService:Create(sanityFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(sVal / 100, 1) })
		:Play()

	queueLabel.Text = `{guest.guestsLeft} in queue · [G] Ask · [T] Phone · [Q] UV`
	statusLabel.Text =
		"Guest at the desk. Inspect documents, ask questions [G], call room [T], or check UV seal [Q]."

	GuestRenderer.arrive(guest)
	DeskProps.updateLedger(guest)

	setPrompt(true)
end

function DeskUI.onResult(result)
	setPrompt(false)
	phoneBannerFrame.Visible = false

	local sVal = result.sanity or 100
	sanityLabel.Text = `{sVal}%`
	TweenService:Create(sanityFill, TweenInfo.new(0.4), { Size = UDim2.fromScale(sVal / 100, 1) })
		:Play()
	takingsLabel.Text = `SAFE: ${result.takings or 0}`

	Atmosphere.onSanityChanged(sVal)

	if result.correct then
		Atmosphere.playSound("cash", nil, 0.8)
		statusLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
		local truth = if result.wasAnomaly
			then `✓ Correctly refused anomaly ({result.tell or "unnatural entity"}). Safe +$40.`
			else "✓ Correctly admitted genuine guest. Safe +$40."
		statusLabel.Text = truth
	else
		Atmosphere.playSound("heartbeat", nil, 0.9)
		Atmosphere.shakeCamera()
		statusLabel.TextColor3 = Color3.fromRGB(240, 90, 80)
		local reason = if result.wasAnomaly
			then "✗ Breach! Anomaly was admitted into the motel. Sanity damaged (-40%)."
			else "✗ Mistake! A genuine paying guest was turned away. Sanity damaged (-20%)."
		statusLabel.Text = reason
	end
end

function DeskUI.onShiftEnded(result)
	setPrompt(false)
	phoneBannerFrame.Visible = false
	GuestRenderer.cleanup()
	DeskProps.clearLedger()

	if result and result.survived ~= nil then
		if result.survived then
			statusLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
			statusLabel.Text =
				`Shift Completed! You survived Night {result.nightsWorked} with {result.sanity}% sanity. Safe: ${result.takings}`
		else
			statusLabel.TextColor3 = Color3.fromRGB(240, 90, 80)
			statusLabel.Text =
				`Sanity broke on Night {result.nightsWorked}. Shift ended immediately.`
		end
	else
		statusLabel.Text = "The night shift is over."
	end
end

return DeskUI
