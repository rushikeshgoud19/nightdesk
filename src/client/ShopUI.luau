--!strict
-- The shop, shown between nights. Renders whatever the server says and holds no
-- opinion of its own -- every price, every owned flag, every "you can't afford
-- this" reason arrives over the wire already decided.
--
-- The client never subtracts money. It asks, and the server answers with a new
-- state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Theme = require(script.Parent:WaitForChild("Theme"))

local requestPurchase = Remotes.get("RequestPurchase")
local startShift = Remotes.get("StartShift")

local ROW_HEIGHT = 74
local PANEL_WIDTH = 560

local ShopUI = {}

local root: Frame
local header: TextLabel
local statsLabel: TextLabel
local listFrame: ScrollingFrame
local openButton: TextButton
local rows: { Frame } = {}

function ShopUI.build(gui: ScreenGui)
	root = Theme.frame(
		gui,
		UDim2.fromOffset(PANEL_WIDTH, 520),
		UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -260)
	)
	root.Visible = false

	header = Theme.label(root, UDim2.new(1, -44, 0, 30), UDim2.fromOffset(22, 20), 22)
	header.Text = "The motel"

	statsLabel = Theme.label(root, UDim2.new(1, -44, 0, 40), UDim2.fromOffset(22, 52), 14)
	statsLabel.TextColor3 = Theme.inkSoft
	statsLabel.TextWrapped = true

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -44, 1, -180)
	listFrame.Position = UDim2.fromOffset(22, 100)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.CanvasSize = UDim2.new()
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listFrame

	openButton =
		Theme.button(root, UDim2.new(1, -44, 0, 46), UDim2.new(0, 22, 1, -66), "Open for the night")
	openButton.Activated:Connect(function()
		root.Visible = false
		startShift:FireServer()
	end)
end

local function renderRow(index: number, item): Frame
	local row = rows[index]
	if not row then
		row = Theme.frame(listFrame, UDim2.new(1, -8, 0, ROW_HEIGHT), UDim2.new())
		row.BackgroundColor3 = Theme.panelLit
		row.LayoutOrder = index

		local name = Theme.label(row, UDim2.new(1, -150, 0, 20), UDim2.fromOffset(14, 12), 16)
		name.Name = "ItemName"

		local blurb = Theme.label(row, UDim2.new(1, -150, 0, 32), UDim2.fromOffset(14, 34), 13)
		blurb.Name = "Blurb"
		blurb.TextColor3 = Theme.inkSoft
		blurb.TextWrapped = true

		local buy = Theme.button(row, UDim2.fromOffset(112, 34), UDim2.new(1, -126, 0, 20), "Buy")
		buy.Name = "Buy"

		rows[index] = row
	end

	local name = row:FindFirstChild("ItemName") :: TextLabel
	local blurb = row:FindFirstChild("Blurb") :: TextLabel
	local buy = row:FindFirstChild("Buy") :: TextButton

	name.Text = item.name
	blurb.Text = item.blurb

	if item.owned then
		buy.Text = "Owned"
		Theme.setEnabled(buy, false)
	elseif item.buyable then
		buy.Text = `Buy · {item.cost}`
		Theme.setEnabled(buy, true)
	else
		buy.Text = item.reason or "Locked"
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
		then "Broke (Forfeited takings)"
		else "Survived"
	statsLabel.Text = string.format(
		"Night %d finished · %s · %d in the safe\n%d guests a night · %d%% of anomalies show a tell · %d a correct call",
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

	-- Hide rows left over from a shorter catalogue.
	for i = #state.items + 1, #rows do
		rows[i].Visible = false
	end

	root.Visible = true
end

return ShopUI
