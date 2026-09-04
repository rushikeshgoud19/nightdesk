--!strict
-- The desk interface: High-fidelity analog horror HUD with dynamic EKG sanity bar,
-- tactile [Z]/[X] verdict stamps, tape-recorder subtitle banner, and [G] Intercom modal.

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
local timeTick = Remotes.get("TimeTick")

local DeskUI = {}

local currentNightNumber = 1
local currentGuestAtDesk = false
local wasWaiting = false

local hudFrame: Frame
local nightBadge: Frame
local nightLabel: TextLabel
local takingsBadge: Frame
local takingsLabel: TextLabel
local sanityFill: Frame
local sanityLabel: TextLabel
local sanityIcon: TextLabel
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
	if bottomBar then
		bottomBar.Visible = visible
		if visible then
			bottomBar.Position = UDim2.new(0.5, -420, 1, -12)
			TweenService:Create(
				bottomBar,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.new(0.5, -420, 1, -94),
				}
			):Play()
		end
	end
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
	Atmosphere.playSound("stamp", nil, 0.9)
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
	-- The stamps are physical props owned by DeskProps, but the verdict and its
	-- cleanup live here. Give DeskProps the guarded entry point rather than
	-- letting it fire the remote itself.
	DeskProps.setVerdictHandler(DeskUI.send)

	-- 1. Sleek Top HUD Bar
	hudFrame = Theme.card(
		gui,
		UDim2.new(1, -48, 0, 48),
		UDim2.fromOffset(24, 12),
		Color3.fromRGB(14, 17, 16),
		Color3.fromRGB(38, 52, 45)
	)

	-- Night Shift Badge
	nightBadge = Theme.badge(
		hudFrame,
		UDim2.fromOffset(175, 30),
		UDim2.fromOffset(10, 9),
		"NIGHT 1 · 02:00 AM",
		Color3.fromRGB(24, 34, 28),
		Color3.fromRGB(120, 225, 150)
	)
	nightLabel = nightBadge:FindFirstChildWhichIsA("TextLabel") :: TextLabel
	nightLabel.Font = Enum.Font.GothamBold

	-- Takings Safe Badge
	takingsBadge = Theme.badge(
		hudFrame,
		UDim2.fromOffset(130, 30),
		UDim2.fromOffset(195, 9),
		"SAFE: $0",
		Color3.fromRGB(22, 38, 30),
		Color3.fromRGB(110, 230, 145)
	)
	takingsLabel = takingsBadge:FindFirstChildWhichIsA("TextLabel") :: TextLabel
	takingsLabel.Font = Enum.Font.GothamBold

	-- EKG Sanity Container
	local sanityContainer = Instance.new("Frame")
	sanityContainer.Size = UDim2.fromOffset(250, 30)
	sanityContainer.Position = UDim2.new(0.5, -125, 0, 9)
	sanityContainer.BackgroundTransparency = 1
	sanityContainer.Parent = hudFrame

	sanityIcon = Theme.label(
		sanityContainer,
		UDim2.fromOffset(75, 30),
		UDim2.new(),
		12,
		Enum.Font.GothamBold
	)
	sanityIcon.TextColor3 = Color3.fromRGB(80, 210, 245)
	sanityIcon.Text = "♥ SANITY:"

	local sanityBarBg = Instance.new("Frame")
	sanityBarBg.Size = UDim2.fromOffset(125, 10)
	sanityBarBg.Position = UDim2.fromOffset(80, 10)
	sanityBarBg.BackgroundColor3 = Color3.fromRGB(25, 32, 30)
	sanityBarBg.BorderSizePixel = 0
	Theme.corner(sanityBarBg, 5)
	Theme.stroke(sanityBarBg, Color3.fromRGB(45, 58, 52), 1, 0.4)
	sanityBarBg.Parent = sanityContainer

	sanityFill = Instance.new("Frame")
	sanityFill.Size = UDim2.fromScale(1, 1)
	sanityFill.BackgroundColor3 = Color3.fromRGB(75, 205, 235)
	sanityFill.BorderSizePixel = 0
	Theme.corner(sanityFill, 5)
	sanityFill.Parent = sanityBarBg

	sanityLabel = Theme.label(
		sanityContainer,
		UDim2.fromOffset(45, 30),
		UDim2.fromOffset(212, 0),
		12,
		Enum.Font.RobotoMono
	)
	sanityLabel.TextColor3 = Theme.inkSoft
	sanityLabel.Text = "100%"

	-- Right Controls Guide Badge
	queueLabel = Theme.label(
		hudFrame,
		UDim2.fromOffset(420, 30),
		UDim2.new(1, -430, 0, 9),
		12,
		Enum.Font.RobotoMono
	)
	queueLabel.TextColor3 = Theme.inkSoft
	queueLabel.TextXAlignment = Enum.TextXAlignment.Right
	queueLabel.Text = "[E] Bell · [F] Ledger · [G] Ask · [T] Phone · [Q] UV"

	-- Status Feedback Banner
	statusLabel =
		Theme.label(gui, UDim2.fromOffset(900, 24), UDim2.fromOffset(32, 68), 13, Enum.Font.Code)
	statusLabel.TextColor3 = Theme.inkSoft
	statusLabel.Text = "Shift active. Ring the bell [E] to summon the next guest."

	-- 2. Tape Recorder Subtitle Banner
	phoneBannerFrame = Theme.card(
		gui,
		UDim2.new(1, -64, 0, 46),
		UDim2.new(0, 32, 1, -155),
		Color3.fromRGB(10, 12, 14),
		Color3.fromRGB(65, 80, 72)
	)
	phoneBannerFrame.Visible = false

	phoneSubtitleLabel = Theme.label(
		phoneBannerFrame,
		UDim2.new(1, -24, 1, 0),
		UDim2.fromOffset(14, 0),
		14,
		Enum.Font.SpecialElite
	)
	phoneSubtitleLabel.TextColor3 = Color3.fromRGB(245, 215, 130)
	phoneSubtitleLabel.Text = ""

	-- 3. Intercom Questioning Modal
	intercomModal = Theme.card(
		gui,
		UDim2.fromOffset(480, 185),
		UDim2.new(0.5, -240, 0.5, -92),
		Color3.fromRGB(15, 18, 22),
		Color3.fromRGB(55, 75, 65)
	)
	intercomModal.Visible = false

	local iHeader = Theme.label(
		intercomModal,
		UDim2.new(1, -24, 0, 26),
		UDim2.fromOffset(14, 10),
		14,
		Enum.Font.GothamBold
	)
	iHeader.TextColor3 = Color3.fromRGB(245, 215, 130)
	iHeader.Text = "DESK INTERCOM · SELECT QUESTION [G]"

	local q1 = Theme.button(
		intercomModal,
		UDim2.new(1, -28, 0, 36),
		UDim2.fromOffset(14, 42),
		'1. "State your purpose of stay."',
		Color3.fromRGB(25, 32, 38),
		Theme.ink
	)
	q1.Font = Enum.Font.RobotoMono
	q1.TextSize = 12
	q1.Activated:Connect(function()
		DeskUI.ask("purpose")
	end)

	local q2 = Theme.button(
		intercomModal,
		UDim2.new(1, -28, 0, 36),
		UDim2.fromOffset(14, 84),
		'2. "Verify your vehicle license plate."',
		Color3.fromRGB(25, 32, 38),
		Theme.ink
	)
	q2.Font = Enum.Font.RobotoMono
	q2.TextSize = 12
	q2.Activated:Connect(function()
		DeskUI.ask("plate")
	end)

	local q3 = Theme.button(
		intercomModal,
		UDim2.new(1, -28, 0, 36),
		UDim2.fromOffset(14, 126),
		'3. "Look directly into the reception mirror."',
		Color3.fromRGB(25, 32, 38),
		Theme.ink
	)
	q3.Font = Enum.Font.RobotoMono
	q3.TextSize = 12
	q3.Activated:Connect(function()
		DeskUI.ask("mirror")
	end)

	-- 4. Floating Verdict Action Strip
	bottomBar = Theme.card(
		gui,
		UDim2.fromOffset(840, 82),
		UDim2.new(0.5, -420, 1, -94),
		Color3.fromRGB(12, 15, 14),
		Color3.fromRGB(45, 60, 52)
	)
	bottomBar.Visible = false

	guestBriefLabel = Theme.label(
		bottomBar,
		UDim2.new(0.55, -20, 0, 24),
		UDim2.fromOffset(18, 12),
		15,
		Enum.Font.GothamBold
	)
	guestBriefLabel.TextColor3 = Theme.inkBright

	tellHighlightLabel = Theme.label(
		bottomBar,
		UDim2.new(0.55, -20, 0, 36),
		UDim2.fromOffset(18, 38),
		13,
		Enum.Font.Code
	)
	tellHighlightLabel.TextColor3 = Color3.fromRGB(245, 175, 65)
	tellHighlightLabel.TextWrapped = true

	admitButton = Theme.button(
		bottomBar,
		UDim2.fromOffset(165, 52),
		UDim2.new(1, -360, 0.5, -26),
		"ADMIT  [Z]",
		Color3.fromRGB(48, 145, 75),
		Theme.inkBright
	)

	refuseButton = Theme.button(
		bottomBar,
		UDim2.fromOffset(165, 52),
		UDim2.new(1, -185, 0.5, -26),
		"REFUSE  [X]",
		Color3.fromRGB(180, 50, 45),
		Theme.inkBright
	)

	admitButton.Activated:Connect(function()
		DeskUI.send(true)
	end)
	refuseButton.Activated:Connect(function()
		DeskUI.send(false)
	end)

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
				then Color3.fromRGB(255, 70, 60)
				else Color3.fromRGB(120, 230, 150)
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
			then Color3.fromRGB(255, 80, 70)
			else Color3.fromRGB(225, 235, 240)
		if data.isCreepy then
			Atmosphere.playSound("heartbeat", nil, 0.7)
		end
		task.delay(7.0, function()
			if phoneSubtitleLabel.Text == `🎙 GUEST INTERCOM: "{data.answer}"` then
				phoneBannerFrame.Visible = false
			end
		end)
	end)

	timeTick.OnClientEvent:Connect(function(data)
		local mins = data.time or 0
		local hour = math.floor(mins / 60)
		local min = math.floor(mins % 60)
		local displayHour = if hour == 0 then 12 else hour
		nightLabel.Text =
			string.format("NIGHT %d · %02d:%02d AM", currentNightNumber, displayHour, min)

		-- Somebody is at the door. Say so, and say it louder as their patience
		-- runs out -- they leave on their own and it costs $10.
		if not currentGuestAtDesk then
			if data.waiting then
				local left = data.waitLeft or 0
				statusLabel.Text = if left < 8
					then "Someone is still waiting at the door. Ring the bell [E] before they leave."
					else "Someone has come in out of the rain. Ring the bell [E] to call them up."
				statusLabel.TextColor3 = if left < 8
					then Color3.fromRGB(245, 130, 60)
					else Color3.fromRGB(235, 215, 165)
			elseif wasWaiting then
				-- They gave up and walked back out into the rain, and that costs
				-- $10. Without this branch the "someone is waiting" line stayed on
				-- screen after they had gone, which is worse than saying nothing.
				statusLabel.Text = "They gave up waiting and walked back out. -$10."
				statusLabel.TextColor3 = Color3.fromRGB(245, 130, 60)
			end
			wasWaiting = data.waiting == true
		end
	end)
end

function DeskUI.onGuest(guest)
	ShopUI.close()
	currentGuestAtDesk = true
	if guest.nightNumber then
		currentNightNumber = guest.nightNumber
	end
	guestBriefLabel.Text =
		`GUEST: {guest.name}  ·  Res #{guest.reservation}  ·  Room {guest.roomNumber or 101}`

	if guest.tell then
		tellHighlightLabel.Text = `OBSERVATION: {guest.tell}`
		tellHighlightLabel.TextColor3 = Color3.fromRGB(250, 165, 60)
	else
		tellHighlightLabel.Text =
			"Observation: Inspect ledger [F], ask question [G], call room [T], or check UV [Q]."
		tellHighlightLabel.TextColor3 = Theme.inkSoft
	end

	takingsLabel.Text = `SAFE: ${guest.takings or 0}`
	local sVal = guest.sanity or 100
	sanityLabel.Text = `{sVal}%`

	local sColor = if sVal > 65
		then Color3.fromRGB(75, 205, 235)
		elseif sVal > 30 then Color3.fromRGB(245, 180, 55)
		else Color3.fromRGB(245, 60, 50)
	sanityFill.BackgroundColor3 = sColor
	sanityIcon.TextColor3 = sColor
	TweenService
		:Create(sanityFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(sVal / 100, 1),
		})
		:Play()

	-- The night runs on a clock now, not a guest counter, so `guestsLeft` stopped
	-- being sent and this rendered a literal "nil remaining" on the HUD all shift.
	-- How much night is left is the clock's job; this line is for the tools.
	queueLabel.Text = "[G] Ask · [T] Phone · [Q] UV · [F] Ledger"
	statusLabel.Text =
		"Guest at the desk. Inspect documents, ask questions [G], or test UV seal [Q]."
	statusLabel.TextColor3 = Theme.inkSoft

	GuestRenderer.arrive(guest)
	DeskProps.updateLedger(guest)

	setPrompt(true)
end

-- The sanity bar and the takings badge. Shared by the verdict path and the
-- coffee/soda path, which are otherwise nothing alike.
local function setMeters(sanity: number, takings: number)
	sanityLabel.Text = `{sanity}%`

	local sColor = if sanity > 65
		then Color3.fromRGB(75, 205, 235)
		elseif sanity > 30 then Color3.fromRGB(245, 180, 55)
		else Color3.fromRGB(245, 60, 50)
	sanityFill.BackgroundColor3 = sColor
	sanityIcon.TextColor3 = sColor
	TweenService
		:Create(sanityFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(sanity / 100, 1),
		})
		:Play()

	takingsLabel.Text = `SAFE: ${takings}`
	Atmosphere.onSanityChanged(sanity)
end

-- Sanity moved, but nobody was judged. Coffee and soda used to arrive on the
-- verdict remote, so drinking one printed "Correctly admitted genuine guest,
-- +$40" over a guest still standing at the desk, and cleared their prompt.
function DeskUI.onSanity(payload)
	setMeters(payload.sanity or 100, payload.takings or 0)
end

function DeskUI.onResult(result)
	currentGuestAtDesk = false
	setPrompt(false)
	phoneBannerFrame.Visible = false

	setMeters(result.sanity or 100, result.takings or 0)

	if result.correct then
		Atmosphere.playSound("cash", nil, 0.8)
		statusLabel.TextColor3 = Color3.fromRGB(120, 230, 150)
		local paid = result.paid or 0
		local truth = if result.wasAnomaly
			then `✓ Correctly refused anomaly ({result.tell or "unnatural entity"}). Safe +${paid}.`
			else `✓ Correctly admitted genuine guest. Safe +${paid}.`
		statusLabel.Text = truth
	else
		Atmosphere.playSound("heartbeat", nil, 0.9)
		Atmosphere.shakeCamera()
		statusLabel.TextColor3 = Color3.fromRGB(245, 80, 70)
		local lost = result.sanityLost or 0
		local reason = if result.wasAnomaly
			then `✗ Breach! Anomaly was admitted into the motel. Sanity damaged (-{lost}%).`
			else `✗ Mistake! A genuine paying guest was turned away. Sanity damaged (-{lost}%).`
		statusLabel.Text = reason
	end
end

function DeskUI.onShiftEnded(result)
	currentGuestAtDesk = false
	setPrompt(false)
	phoneBannerFrame.Visible = false
	GuestRenderer.cleanup()
	DeskProps.clearLedger()

	if result and result.survived ~= nil then
		local seedText = if result.seed then ` · Seed: {result.seed}` else ""
		if result.survived then
			statusLabel.TextColor3 = Color3.fromRGB(120, 230, 150)
			statusLabel.Text =
				`Shift Completed! You survived Night {result.nightsWorked} with {result.sanity}% sanity. Safe: ${result.takings}{seedText}`
		else
			statusLabel.TextColor3 = Color3.fromRGB(245, 80, 70)
			statusLabel.Text =
				`Sanity broke on Night {result.nightsWorked}. Shift ended immediately.{seedText}`
		end
	else
		statusLabel.Text = "The night shift is over."
	end
end

return DeskUI
