--!strict
-- Shared UI constants, procedural CRT scanlines, styling, and interactive button helpers.
-- Guarantees a cohesive analog horror / vintage highway motel terminal aesthetic.

local TweenService = game:GetService("TweenService")

local Theme = {}

-- Palette
Theme.ink = Color3.fromRGB(235, 240, 238)
Theme.inkBright = Color3.fromRGB(255, 255, 255)
Theme.inkSoft = Color3.fromRGB(160, 172, 168)
Theme.inkDim = Color3.fromRGB(105, 118, 114)

Theme.panel = Color3.fromRGB(15, 18, 16)
Theme.panelDark = Color3.fromRGB(10, 12, 11)
Theme.panelLit = Color3.fromRGB(24, 30, 26)
Theme.panelBorder = Color3.fromRGB(42, 54, 48)

Theme.accent = Color3.fromRGB(205, 145, 60)
Theme.accentInk = Color3.fromRGB(14, 18, 16)
Theme.accentGreen = Color3.fromRGB(55, 165, 85)
Theme.accentGreenGlow = Color3.fromRGB(90, 220, 125)
Theme.accentRed = Color3.fromRGB(195, 55, 50)
Theme.accentRedGlow = Color3.fromRGB(245, 85, 80)
Theme.accentCyan = Color3.fromRGB(75, 195, 235)
Theme.accentAmber = Color3.fromRGB(245, 180, 55)
Theme.dead = Color3.fromRGB(48, 54, 52)

function Theme.corner(parent: Instance, radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

function Theme.stroke(
	parent: Instance,
	color: Color3?,
	thickness: number?,
	transparency: number?
): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.panelBorder
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function Theme.frame(parent: Instance, size: UDim2, pos: UDim2, bgColor: Color3?): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = bgColor or Theme.panel
	f.BorderSizePixel = 0
	Theme.corner(f, 6)
	Theme.stroke(f, Theme.panelBorder, 1, 0.2)
	f.Parent = parent
	return f
end

function Theme.card(
	parent: Instance,
	size: UDim2,
	pos: UDim2,
	bgColor: Color3?,
	strokeColor: Color3?
): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = bgColor or Theme.panelDark
	f.BorderSizePixel = 0
	Theme.corner(f, 8)
	Theme.stroke(f, strokeColor or Theme.panelBorder, 1.5, 0.1)
	f.Parent = parent
	return f
end

function Theme.label(
	parent: Instance,
	size: UDim2,
	pos: UDim2,
	textSize: number,
	font: Enum.Font?
): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Font = font or Enum.Font.Code
	l.TextSize = textSize
	l.TextColor3 = Theme.ink
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Text = ""
	l.Parent = parent
	return l
end

function Theme.badge(
	parent: Instance,
	size: UDim2,
	pos: UDim2,
	text: string,
	bgCol: Color3?,
	textCol: Color3?
): Frame
	local b = Instance.new("Frame")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bgCol or Theme.panelLit
	b.BorderSizePixel = 0
	Theme.corner(b, 4)
	Theme.stroke(b, (bgCol or Theme.panelLit):Lerp(Color3.new(1, 1, 1), 0.2), 1, 0.3)

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.RobotoMono
	txt.TextSize = 12
	txt.TextColor3 = textCol or Theme.ink
	txt.Text = text
	txt.Parent = b

	b.Parent = parent
	return b
end

function Theme.button(
	parent: Instance,
	size: UDim2,
	pos: UDim2,
	text: string,
	bgCol: Color3?,
	textCol: Color3?
): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bgCol or Theme.accent
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = textCol or Theme.accentInk
	b.Text = text
	b.AutoButtonColor = false

	Theme.corner(b, 6)
	local s = Theme.stroke(b, (bgCol or Theme.accent):Lerp(Color3.new(1, 1, 1), 0.25), 1.5, 0.2)

	local origColor = bgCol or Theme.accent
	local hoverColor = origColor:Lerp(Color3.new(1, 1, 1), 0.18)
	local pressColor = origColor:Lerp(Color3.new(0, 0, 0), 0.25)

	b.MouseEnter:Connect(function()
		if b.Active then
			TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = hoverColor }):Play()
			TweenService:Create(s, TweenInfo.new(0.15), { Thickness = 2, Transparency = 0 }):Play()
		end
	end)

	b.MouseLeave:Connect(function()
		if b.Active then
			TweenService:Create(b, TweenInfo.new(0.2), { BackgroundColor3 = origColor }):Play()
			TweenService:Create(s, TweenInfo.new(0.2), { Thickness = 1.5, Transparency = 0.2 })
				:Play()
		end
	end)

	b.MouseButton1Down:Connect(function()
		if b.Active then
			TweenService:Create(b, TweenInfo.new(0.08), { BackgroundColor3 = pressColor }):Play()
		end
	end)

	b.MouseButton1Up:Connect(function()
		if b.Active then
			TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = hoverColor }):Play()
		end
	end)

	b.Parent = parent
	return b
end

function Theme.setEnabled(b: TextButton, enabled: boolean, activeBg: Color3?, activeText: Color3?)
	b.Active = enabled
	local targetBg = if enabled then (activeBg or Theme.accent) else Theme.dead
	local targetText = if enabled then (activeText or Theme.accentInk) else Theme.inkDim
	b.BackgroundColor3 = targetBg
	b.TextColor3 = targetText

	local s = b:FindFirstChildWhichIsA("UIStroke")
	if s then
		s.Color = if enabled then targetBg:Lerp(Color3.new(1, 1, 1), 0.2) else Theme.panelBorder
	end
end

-- Ambient CRT scanline overlay
function Theme.attachCRTOverlay(gui: ScreenGui)
	local overlay = Instance.new("Frame")
	overlay.Name = "CRT_Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Position = UDim2.new()
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 100
	overlay.Parent = gui

	-- Vignette shadow
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
	vignette.ImageTransparency = 0.85
	vignette.ZIndex = 100
	vignette.Parent = overlay

	-- Live VHS Watermark
	local vhsLabel = Instance.new("TextLabel")
	vhsLabel.Name = "VHS_Timestamp"
	vhsLabel.Size = UDim2.fromOffset(450, 24)
	vhsLabel.Position = UDim2.fromOffset(24, 20)
	vhsLabel.BackgroundTransparency = 1
	vhsLabel.Font = Enum.Font.RobotoMono
	vhsLabel.TextSize = 12
	vhsLabel.TextColor3 = Color3.fromRGB(140, 230, 160)
	vhsLabel.TextTransparency = 0.4
	vhsLabel.TextXAlignment = Enum.TextXAlignment.Left
	vhsLabel.Text = "● REC [02:00:00 AM] · CH-01 FRONT DESK · CRESTVIEW MOTEL"
	vhsLabel.ZIndex = 101
	vhsLabel.Parent = overlay

	task.spawn(function()
		local count = 0
		while overlay.Parent ~= nil do
			task.wait(1)
			count += 1
			local secs = count % 60
			local mins = math.floor(count / 60) % 60
			local blink = if count % 2 == 0 then "●" else "○"
			vhsLabel.Text = string.format(
				"%s REC [02:%02d:%02d AM] · CH-01 FRONT DESK · CRESTVIEW MOTEL",
				blink,
				mins,
				secs
			)
		end
	end)
end

return Theme
