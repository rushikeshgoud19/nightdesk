--!strict
-- The desk. Shows who is standing in front of you and takes your call.
--
-- Holds no score. Every number on screen arrived from the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))

local judge = Remotes.get("Judge")

local CARD_W, CARD_H = 440, 200

local DeskUI = {}

local card: Frame
local nameLabel: TextLabel
local resLabel: TextLabel
local tellLabel: TextLabel
local statusLabel: TextLabel
local admitButton: TextButton
local refuseButton: TextButton
local awaiting = false

local function setPrompt(visible: boolean)
	awaiting = visible
	card.Visible = visible
end

local function send(admitted: boolean)
	if not awaiting then
		return
	end
	setPrompt(false)
	judge:FireServer(admitted)
end

function DeskUI.build(gui: ScreenGui)
	statusLabel = Theme.label(gui, UDim2.fromOffset(700, 26), UDim2.fromOffset(24, 24), 15)
	statusLabel.TextColor3 = Theme.inkSoft
	statusLabel.Text = ""

	card = Theme.frame(
		gui,
		UDim2.fromOffset(CARD_W, CARD_H),
		UDim2.new(0.5, -CARD_W / 2, 0.5, -CARD_H / 2)
	)
	card.Visible = false

	nameLabel = Theme.label(card, UDim2.new(1, -36, 0, 28), UDim2.fromOffset(18, 18), 22)
	resLabel = Theme.label(card, UDim2.new(1, -36, 0, 20), UDim2.fromOffset(18, 50), 14)
	resLabel.TextColor3 = Theme.inkSoft

	tellLabel = Theme.label(card, UDim2.new(1, -36, 0, 48), UDim2.fromOffset(18, 78), 14)
	tellLabel.TextColor3 = Theme.accent
	tellLabel.TextWrapped = true

	admitButton =
		Theme.button(card, UDim2.fromOffset(190, 40), UDim2.fromOffset(18, CARD_H - 58), "Admit")
	refuseButton = Theme.button(
		card,
		UDim2.fromOffset(190, 40),
		UDim2.fromOffset(CARD_W - 208, CARD_H - 58),
		"Refuse"
	)
	refuseButton.BackgroundColor3 = Theme.dead
	refuseButton.TextColor3 = Theme.ink

	admitButton.Activated:Connect(function()
		send(true)
	end)
	refuseButton.Activated:Connect(function()
		send(false)
	end)
end

function DeskUI.onGuest(guest)
	nameLabel.Text = guest.name
	resLabel.Text = `Reservation #{guest.reservation}   ·   {guest.guestsLeft} still waiting`
	-- No tell does not mean the guest is fine. It means you cannot see what is
	-- wrong yet -- which is what the upgrades are for.
	tellLabel.Text = guest.tell or "Nothing you can put your finger on."

	if
		statusLabel.Text == ""
		or string.find(statusLabel.Text, "night is over")
		or string.find(statusLabel.Text, "broke")
	then
		statusLabel.Text =
			`Waiting for call...   ·   {guest.takings or 0} in the safe   ·   {guest.sanity or 100} sanity`
	end
	setPrompt(true)
end

function DeskUI.onResult(result)
	setPrompt(false)
	local verdict = if result.correct then "Correct." else "Wrong."
	local truth = if result.wasAnomaly
		then `Anomaly: {result.tell or "something was off"}`
		else "That was a real guest."
	statusLabel.Text =
		`{verdict} {truth}   ·   {result.takings} in the safe   ·   {result.sanity} sanity`
end

function DeskUI.onShiftEnded(result)
	setPrompt(false)
	if result and result.survived ~= nil then
		if result.survived then
			statusLabel.Text = `The night is over. You survived with {result.sanity} sanity.`
		else
			statusLabel.Text = `You broke. Night ended immediately. Takings forfeited.`
		end
	else
		statusLabel.Text = "The night is over."
	end
end

return DeskUI
