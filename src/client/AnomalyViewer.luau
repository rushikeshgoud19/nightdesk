--!strict
-- Studio-only anomaly viewer.
--
-- 42 anomalies is more than anyone can hold in their head, and most of them are
-- meant to be nearly invisible -- which makes "is this one actually rendering?"
-- a question you cannot answer by playing. Six body tells and three behaviour
-- tells shipped broken precisely because nothing ever put them side by side with
-- a genuine guest.
--
-- So: step through every anomaly at the desk, one key at a time, with its id,
-- tier, channel and the exact tell it promises on screen next to it. `\` toggles
-- an innocent guest, which is the only honest way to judge a 4% difference.
--
--   ]   next anomaly          [   previous
--   \   toggle innocent guest  R   reroll who the guest is
--   P   open / close
--
-- Gated on RunService:IsStudio(), so it does not exist in a published place.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anomalies = require(Shared:WaitForChild("Anomalies"))

local AnomalyViewer = {}

local index = 1
local showingInnocent = false
-- Held fixed across steps ON PURPOSE. If the person changes at the same time as
-- the anomaly, nothing is comparable -- and comparing is the entire job here,
-- because most of these tells are a few percent. R rerolls it when you want to
-- see the same tell on a different face.
local personSeed = 20260905
local titleLabel: TextLabel? = nil
local tellLabel: TextLabel? = nil
local metaLabel: TextLabel? = nil

-- Injected rather than required, because GuestRenderer already requires enough
-- of the client and a cycle here would be paid for by every guest in the game.
local renderGuest: ((any) -> ())? = nil

function AnomalyViewer.setRenderer(fn: (any) -> ())
	renderGuest = fn
end

local function show()
	if not renderGuest or not titleLabel or not tellLabel or not metaLabel then
		return
	end

	local list = Anomalies.list
	index = ((index - 1) % #list) + 1
	local a = list[index]

	local forced = if showingInnocent then nil else a
	-- A fixed seed keeps every other visual constant between entries, so the
	-- only thing that changes as you step through is the anomaly itself.
	local guest =
		Anomalies.roll(Random.new(personSeed), 1, { [1] = 1, [2] = 1, [3] = 1 }, false, forced)

	renderGuest({
		name = guest.name,
		reservation = guest.reservation,
		idName = guest.idName,
		checkInDate = guest.checkInDate,
		checkOutDate = guest.checkOutDate,
		roomNumber = guest.roomNumber,
		cityOrigin = guest.cityOrigin,
		zipCode = guest.zipCode,
		stayLength = guest.stayLength,
		signatureFont = guest.signatureFont,
		watermarkText = guest.watermarkText,
		photoMaskTransparency = guest.photoMaskTransparency,
		licenseExpiry = guest.licenseExpiry,
		tell = if guest.anomaly then guest.anomaly.tell else nil,
		anomalyId = if guest.anomaly then guest.anomaly.id else nil,
		horrorType = if guest.anomaly then guest.anomaly.horrorType else nil,
		uvSymbol = guest.uvSymbol,
		isRoomOccupied = guest.isRoomOccupied,
		visualSeed = personSeed,
		sanity = 100,
		takings = 0,
		nightNumber = 1,
	})

	if showingInnocent then
		titleLabel.Text = `[{index}/{#list}]  GENUINE GUEST`
		titleLabel.TextColor3 = Color3.fromRGB(120, 230, 150)
		metaLabel.Text = `compare against: {a.id}   ·   press \\ to switch back`
		tellLabel.Text = "No anomaly. This is what the difference is measured against."
	else
		titleLabel.Text = `[{index}/{#list}]  {a.id}`
		titleLabel.TextColor3 = Color3.fromRGB(250, 165, 60)
		metaLabel.Text =
			`tier {a.tier}   ·   {a.horrorType}   ·   [ ] step   \\ compare   P first`
		tellLabel.Text = a.tell
	end
end

local function step(n: number)
	index += n
	showingInnocent = false
	show()
end

function AnomalyViewer.init(gui: ScreenGui)
	if not RunService:IsStudio() then
		return
	end

	local p = Instance.new("Frame")
	p.Name = "AnomalyViewer"
	p.Size = UDim2.fromOffset(620, 96)
	p.Position = UDim2.new(0.5, -310, 1, -170)
	p.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	p.BackgroundTransparency = 0.12
	p.BorderSizePixel = 0
	p.Visible = false
	p.Parent = gui

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 3, 1, 0)
	stripe.BackgroundColor3 = Color3.fromRGB(250, 165, 60)
	stripe.BorderSizePixel = 0
	stripe.Parent = p

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -28, 0, 26)
	t.Position = UDim2.fromOffset(18, 8)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 17
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = ""
	t.Parent = p
	titleLabel = t

	local m = Instance.new("TextLabel")
	m.Size = UDim2.new(1, -28, 0, 18)
	m.Position = UDim2.fromOffset(18, 32)
	m.BackgroundTransparency = 1
	m.Font = Enum.Font.Code
	m.TextSize = 12
	m.TextColor3 = Color3.fromRGB(130, 135, 145)
	m.TextXAlignment = Enum.TextXAlignment.Left
	m.Text = ""
	m.Parent = p
	metaLabel = m

	local d = Instance.new("TextLabel")
	d.Size = UDim2.new(1, -34, 0, 38)
	d.Position = UDim2.fromOffset(18, 52)
	d.BackgroundTransparency = 1
	d.Font = Enum.Font.Gotham
	d.TextSize = 13
	d.TextColor3 = Color3.fromRGB(228, 224, 214)
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.TextWrapped = true
	d.Text = ""
	d.Parent = p
	tellLabel = d

	-- Bound once each. Every desk key in this game is bound exactly once, because
	-- a second binding beside a ProximityPrompt makes both fire and cancel.
	ContextActionService:BindAction("ndViewerNext", function(_, state)
		if state == Enum.UserInputState.Begin and p.Visible then
			step(1)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.RightBracket)

	ContextActionService:BindAction("ndViewerPrev", function(_, state)
		if state == Enum.UserInputState.Begin and p.Visible then
			step(-1)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.LeftBracket)

	ContextActionService:BindAction("ndViewerCompare", function(_, state)
		if state == Enum.UserInputState.Begin and p.Visible then
			showingInnocent = not showingInnocent
			show()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.BackSlash)

	ContextActionService:BindAction("ndViewerReroll", function(_, state)
		if state == Enum.UserInputState.Begin and p.Visible then
			personSeed = math.random(1, 9999999)
			show()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R)

	ContextActionService:BindAction("ndViewerToggle", function(_, state)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		p.Visible = not p.Visible
		if p.Visible then
			index = 1
			showingInnocent = false
			show()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.P)

	print(`[nightdesk] anomaly viewer ready -- P to open, {#Anomalies.list} entries`)
end

return AnomalyViewer
