--!strict
-- Shared UI constants and builders. Exists so the desk and the shop cannot drift
-- into looking like two different games, and so colours live in one file when
-- the art pass arrives.

local Theme = {}

Theme.ink = Color3.fromRGB(228, 233, 229)
Theme.inkSoft = Color3.fromRGB(154, 166, 159)
Theme.panel = Color3.fromRGB(22, 28, 25)
Theme.panelLit = Color3.fromRGB(32, 40, 36)
Theme.accent = Color3.fromRGB(190, 132, 56)
Theme.accentInk = Color3.fromRGB(18, 22, 20)
Theme.dead = Color3.fromRGB(70, 78, 74)

function Theme.frame(parent: Instance, size: UDim2, pos: UDim2): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = Theme.panel
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

function Theme.label(parent: Instance, size: UDim2, pos: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextSize = textSize
	l.TextColor3 = Theme.ink
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.Text = ""
	l.Parent = parent
	return l
end

function Theme.button(parent: Instance, size: UDim2, pos: UDim2, text: string): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = Theme.accent
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 15
	b.TextColor3 = Theme.accentInk
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	return b
end

function Theme.setEnabled(b: TextButton, enabled: boolean)
	b.Active = enabled
	b.AutoButtonColor = enabled
	b.BackgroundColor3 = if enabled then Theme.accent else Theme.dead
	b.TextColor3 = if enabled then Theme.accentInk else Theme.inkSoft
end

return Theme
