--!strict
-- The motel renovation & security shop, shown between shifts.
-- Server-authoritative: every price, owned state, and upgrade prerequisite is decided by the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))

local requestPurchase = Remotes.get("RequestPurchase")
local startShift = Remotes.get("StartShift")

local ROW_HEIGHT = 80
local PANEL_WIDTH = 620

local ShopUI = {}

local root: Frame
local header: TextLabel
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
	root = Theme.frame(
		gui,
		UDim2.fromOffset(PANEL_WIDTH, 560),
		UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -280)
	)
	root.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
	root.Visible = false

	header = Theme.label(root, UDim2.new(1, -44, 0, 32), UDim2.fromOffset(22, 18), 22)
	header.Font = Enum.Font.SpecialElite
	header.TextColor3 = Color3.fromRGB(245, 215, 140)
	header.Text = "MOTEL RENOVATION & SECURITY SHOP"

	statsLabel = Theme.label(root, UDim2.new(1, -44, 0, 48), UDim2.fromOffset(22, 54), 13)
	statsLabel.TextColor3 = Theme.inkSoft
	statsLabel.TextWrapped = true

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -44, 1, -195)
	listFrame.Position = UDim2.fromOffset(22, 112)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 5
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 90, 100)
	listFrame.CanvasSize = UDim2.new()
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listFrame

	openButton = Theme.button(
		root,
		UDim2.new(1, -44, 0, 48),
		UDim2.new(0, 22, 1, -68),
		"START NEXT NIGHT SHIFT  ➔"
	)
	openButton.BackgroundColor3 = Color3.fromRGB(45, 120, 65)
	openButton.TextColor3 = Theme.ink
	openButton.Activated:Connect(function()
		root.Visible = false
		startShift:FireServer()
	end)
end

local function renderRow(index: number, item): Frame
	local row = rows[index]
	if not row then
		row = Theme.frame(listFrame, UDim2.new(1, -8, 0, ROW_HEIGHT), UDim2.new())
		row.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
		row.LayoutOrder = index

		local tag = Theme.label(row, UDim2.fromOffset(120, 16), UDim2.fromOffset(14, 10), 11)
		tag.Name = "CategoryTag"
		tag.Font = Enum.Font.RobotoMono
		tag.TextColor3 = Color3.fromRGB(120, 180, 240)

		local name = Theme.label(row, UDim2.new(1, -165, 0, 22), UDim2.fromOffset(14, 28), 15)
		name.Name = "ItemName"
		name.Font = Enum.Font.GothamBold

		local blurb = Theme.label(row, UDim2.new(1, -165, 0, 28), UDim2.fromOffset(14, 48), 12)
		blurb.Name = "Blurb"
		blurb.TextColor3 = Theme.inkSoft
		blurb.TextWrapped = true

		local buy =
			Theme.button(row, UDim2.fromOffset(130, 40), UDim2.new(1, -145, 0.5, -20), "Buy")
		buy.Name = "Buy"

		rows[index] = row
	end

	local tag = row:FindFirstChild("CategoryTag") :: TextLabel
	local name = row:FindFirstChild("ItemName") :: TextLabel
	local blurb = row:FindFirstChild("Blurb") :: TextLabel
	local buy = row:FindFirstChild("Buy") :: TextButton

	local catName = if item.category == "security"
		then "[SECURITY / SURVEILLANCE]"
		elseif item.category == "expansion" then "[MOTEL EXPANSION]"
		else "[INVESTIGATION TOOLS]"
	tag.Text = catName
	name.Text = item.name
	blurb.Text = item.blurb

	if item.owned then
		buy.Text = "OWNED ✓"
		buy.BackgroundColor3 = Color3.fromRGB(35, 45, 40)
		Theme.setEnabled(buy, false)
	elseif item.buyable then
		buy.Text = `BUY · ${item.cost}`
		buy.BackgroundColor3 = Color3.fromRGB(50, 130, 75)
		Theme.setEnabled(buy, true)
	else
		buy.Text = item.reason or "LOCKED"
		buy.BackgroundColor3 = Color3.fromRGB(50, 40, 40)
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
		then "Sanity Broke (Takings Forfeited)"
		else "Shift Survived"
	statsLabel.Text = string.format(
		"Night %d Completed · %s · Safe: $%d\nCapacity: %d guests/night · Tell Clarity: %d%% · Payout: $%d/guest",
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
			requestPurchase:FireServer(id)
		end)
	end

	for i = #state.items + 1, #rows do
		rows[i].Visible = false
	end

	root.Visible = true
end

return ShopUI
