--!strict
-- The motel renovation & security shop, shown between shifts.
-- Server-authoritative: every price, owned state, and upgrade prerequisite is decided by the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Atmosphere = require(script.Parent:WaitForChild("Atmosphere"))
local Theme = require(script.Parent:WaitForChild("Theme"))

local requestPurchase = Remotes.get("RequestPurchase")
local startShift = Remotes.get("StartShift")

local ROW_HEIGHT = 82
local PANEL_WIDTH = 640

local ShopUI = {}

local root: Frame
local header: TextLabel
local subHeader: TextLabel
local statsCard: Frame
local statsLabel: TextLabel
local listFrame: ScrollingFrame
local openButton: TextButton
local rows: { Frame } = {}

function ShopUI.close()
	if root then
		root.Visible = false
	end
end

function ShopUI.build(gui: ScreenGui)
	root = Theme.card(
		gui,
		UDim2.fromOffset(PANEL_WIDTH, 580),
		UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -290),
		Color3.fromRGB(12, 15, 14),
		Color3.fromRGB(48, 65, 56)
	)
	root.Visible = false

	header = Theme.label(
		root,
		UDim2.new(1, -48, 0, 32),
		UDim2.fromOffset(24, 18),
		22,
		Enum.Font.SpecialElite
	)
	header.TextColor3 = Color3.fromRGB(245, 215, 130)
	header.Text = "MOTEL RENOVATION & SECURITY TERMINAL"

	subHeader = Theme.label(
		root,
		UDim2.new(1, -48, 0, 18),
		UDim2.fromOffset(24, 48),
		12,
		Enum.Font.RobotoMono
	)
	subHeader.TextColor3 = Color3.fromRGB(110, 185, 140)
	subHeader.Text = "REINVEST SHIFT TAKINGS INTO SURVEILLANCE & INVESTIGATION TOOLS"

	statsCard = Theme.card(
		root,
		UDim2.new(1, -48, 0, 54),
		UDim2.fromOffset(24, 72),
		Color3.fromRGB(18, 22, 20),
		Color3.fromRGB(36, 48, 42)
	)

	statsLabel =
		Theme.label(statsCard, UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), 13, Enum.Font.Code)
	statsLabel.TextColor3 = Theme.inkSoft
	statsLabel.TextWrapped = true

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -48, 1, -220)
	listFrame.Position = UDim2.fromOffset(24, 136)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 6
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 80, 70)
	listFrame.CanvasSize = UDim2.new()
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listFrame

	openButton = Theme.button(
		root,
		UDim2.new(1, -48, 0, 50),
		UDim2.new(0, 24, 1, -66),
		"COMMENCE NEXT NIGHT SHIFT  ➔",
		Color3.fromRGB(48, 145, 75),
		Theme.inkBright
	)
	openButton.TextSize = 15
	openButton.Activated:Connect(function()
		Atmosphere.playSound("bell", nil, 0.8)
		root.Visible = false
		startShift:FireServer()
	end)
end

local function renderRow(index: number, item): Frame
	local row = rows[index]
	if not row then
		row = Theme.card(
			listFrame,
			UDim2.new(1, -10, 0, ROW_HEIGHT),
			UDim2.new(),
			Color3.fromRGB(18, 23, 21),
			Color3.fromRGB(36, 48, 42)
		)
		row.LayoutOrder = index

		local tagBadge = Theme.badge(
			row,
			UDim2.fromOffset(140, 20),
			UDim2.fromOffset(14, 10),
			"[INVESTIGATION]",
			Color3.fromRGB(24, 34, 30),
			Color3.fromRGB(120, 200, 240)
		)
		tagBadge.Name = "CategoryBadge"

		local name = Theme.label(
			row,
			UDim2.new(1, -185, 0, 22),
			UDim2.fromOffset(14, 34),
			15,
			Enum.Font.GothamBold
		)
		name.Name = "ItemName"
		name.TextColor3 = Theme.inkBright

		local blurb = Theme.label(
			row,
			UDim2.new(1, -185, 0, 24),
			UDim2.fromOffset(14, 55),
			12,
			Enum.Font.Code
		)
		blurb.Name = "Blurb"
		blurb.TextColor3 = Theme.inkSoft
		blurb.TextWrapped = true

		local buy = Theme.button(
			row,
			UDim2.fromOffset(145, 44),
			UDim2.new(1, -160, 0.5, -22),
			"Buy",
			Color3.fromRGB(48, 145, 75),
			Theme.inkBright
		)
		buy.Name = "Buy"

		rows[index] = row
	end

	local tagBadge = row:FindFirstChild("CategoryBadge") :: Frame
	local tagLabel = tagBadge:FindFirstChildWhichIsA("TextLabel") :: TextLabel
	local name = row:FindFirstChild("ItemName") :: TextLabel
	local blurb = row:FindFirstChild("Blurb") :: TextLabel
	local buy = row:FindFirstChild("Buy") :: TextButton

	local catName = if item.category == "security"
		then "[SECURITY / CAMERAS]"
		elseif item.category == "expansion" then "[MOTEL CAPACITY]"
		else "[INVESTIGATION TOOLS]"
	tagLabel.Text = catName
	name.Text = item.name
	blurb.Text = item.blurb

	if item.owned then
		buy.Text = "OWNED ✓"
		buy.BackgroundColor3 = Color3.fromRGB(32, 42, 36)
		Theme.setEnabled(buy, false)
	elseif item.buyable then
		buy.Text = `BUY · ${item.cost}`
		buy.BackgroundColor3 = Color3.fromRGB(48, 145, 75)
		Theme.setEnabled(buy, true, Color3.fromRGB(48, 145, 75), Theme.inkBright)
	else
		buy.Text = item.reason or "LOCKED"
		buy.BackgroundColor3 = Color3.fromRGB(45, 35, 35)
		Theme.setEnabled(buy, false)
	end

	row.Visible = true
	return row
end

local connections: { [TextButton]: RBXScriptConnection } = {}

function ShopUI.render(state)
	if not root then
		return
	end

	local outcome = if state.lastShiftSurvived == false
		then "Sanity Depleted (Takings Forfeited)"
		else "Shift Survived"
	statsLabel.Text = string.format(
		"Night %d Complete · %s · Safe Balance: $%d\nCapacity: %d guests/night · Tell Clarity: %d%% · Payout: $%d/guest",
		state.nightsWorked,
		outcome,
		state.takings,
		state.guestsPerShift,
		math.floor(state.tellChance * 100 + 0.5),
		state.payout
	)

	for i, item in state.items do
		local row = renderRow(i, item)
		local buy = row:FindFirstChild("Buy") :: TextButton
		if connections[buy] then
			connections[buy]:Disconnect()
		end
		local id = item.id
		connections[buy] = buy.Activated:Connect(function()
			Atmosphere.playSound("cash", nil, 0.7)
			requestPurchase:FireServer(id)
		end)
	end

	for i = #state.items + 1, #rows do
		rows[i].Visible = false
	end

	root.Visible = true
	root.Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -270)
	TweenService
		:Create(root, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -290),
		})
		:Play()
end

return ShopUI
