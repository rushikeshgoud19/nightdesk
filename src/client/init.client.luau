--!strict
-- Night desk, client side. Renders the guest at the counter and sends one
-- boolean back. Holds no score of its own -- every number on screen came from
-- the server.
--
-- This UI is built in code on purpose: it stays in git, it diffs, and it is not
-- something you have to rebuild by hand in Studio after every sync.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local guestArrived = Remotes.get("GuestArrived")
local judge = Remotes.get("Judge")
local shiftUpdate = Remotes.get("ShiftUpdate")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "NightDesk"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function label(name: string, size: UDim2, pos: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextSize = textSize
	l.TextColor3 = Color3.fromRGB(228, 233, 229)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = ""
	l.Parent = gui
	return l
end

local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(420, 190)
card.Position = UDim2.new(0.5, -210, 0.5, -95)
card.BackgroundColor3 = Color3.fromRGB(22, 28, 25)
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local nameLabel = label("Guest", UDim2.fromOffset(380, 30), UDim2.new(0.5, -190, 0.5, -80), 22)
local resLabel = label("Reservation", UDim2.fromOffset(380, 22), UDim2.new(0.5, -190, 0.5, -48), 15)
local tellLabel = label("Tell", UDim2.fromOffset(380, 44), UDim2.new(0.5, -190, 0.5, -20), 15)
tellLabel.TextWrapped = true
tellLabel.TextColor3 = Color3.fromRGB(190, 132, 56)

local statusLabel = label("Status", UDim2.fromOffset(500, 26), UDim2.fromOffset(24, 24), 16)
statusLabel.TextColor3 = Color3.fromRGB(154, 166, 159)

local function button(text: string, xOffset: number, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(180, 44)
	b.Position = UDim2.new(0.5, xOffset, 0.5, 40)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 16
	b.TextColor3 = Color3.fromRGB(18, 22, 20)
	b.Text = text
	b.Visible = false
	b.Parent = gui
	return b
end

local admitButton = button("Admit", -190, Color3.fromRGB(176, 116, 31))
local refuseButton = button("Refuse", 10, Color3.fromRGB(150, 154, 151))

local awaiting = false

local function setPrompt(visible: boolean)
	awaiting = visible
	card.Visible = visible
	nameLabel.Visible = visible
	resLabel.Visible = visible
	tellLabel.Visible = visible
	admitButton.Visible = visible
	refuseButton.Visible = visible
end

setPrompt(false)
statusLabel.Text = "Takings 0   ·   Mistakes 0"

guestArrived.OnClientEvent:Connect(function(guest)
	nameLabel.Text = guest.name
	resLabel.Text = `Reservation #{guest.reservation}`
	tellLabel.Text = guest.tell or "Nothing seems out of place."
	setPrompt(true)
end)

shiftUpdate.OnClientEvent:Connect(function(result)
	setPrompt(false)
	local verdict = if result.correct then "Correct." else "Wrong."
	local truth = if result.wasAnomaly then "That was an anomaly." else "That was a real guest."
	statusLabel.Text =
		`{verdict} {truth}   ·   Takings {result.takings}   ·   Mistakes {result.mistakes}`
end)

local function send(admitted: boolean)
	if not awaiting then
		return
	end
	setPrompt(false)
	judge:FireServer(admitted)
end

admitButton.Activated:Connect(function()
	send(true)
end)
refuseButton.Activated:Connect(function()
	send(false)
end)

print("[nightdesk] client up")
