--[[
	╔══════════════════════════════════════════════════════════════╗
	║  Kwargs UI Library  ·  v3.0.0   "Aurora"                     ║
	║  Glass-style, animated, themeable Roblox UI library.         ║
	╚══════════════════════════════════════════════════════════════╝

	Backwards compatible with v1 / v2:
		Lib:Create{} → UI:Tab{} → Tab:Divider{} → Divider:Button / Toggle /
		Dropdown / SearchDropdown / ColorPicker / Box / Slider / Keybind / Label

	New in v3:
		• New "Aurora" look: glass window, animated gradient border,
		  sliding tab pill, gradient title with shimmer.
		• Animations everywhere: open/close fade + scale, page transitions,
		  click ripples, hover glow, squash-and-stretch toggles, growing
		  slider knob, staggered dropdown options, sliding notifications.
		• Executor compatibility layer (Xeno, Solara and other limited
		  executors): every optional API (gethui, cloneref, file functions,
		  identifyexecutor) is feature-detected with safe fallbacks.
		• Opts: Animated = false  → turns off the looping effects (low-end PCs)
]]

local Library = { Version = "3.0.0" }
Library.__index = Library

--============================================================================
-- Compatibility layer (Xeno / Solara / anything with a partial UNC)
--============================================================================
local function Service(name)
	local s = game:GetService(name)
	if type(cloneref) == "function" then
		local ok, c = pcall(cloneref, s)
		if ok and c then return c end
	end
	return s
end

local Players          = Service("Players")
local TweenService     = Service("TweenService")
local UserInputService = Service("UserInputService")
local HttpService      = Service("HttpService")
local RunService       = Service("RunService")

local rgb = Color3.fromRGB
local WHITE = rgb(255, 255, 255)

local ExecutorName = "Unknown"
if type(identifyexecutor) == "function" then
	local ok, name = pcall(identifyexecutor)
	if ok and name then ExecutorName = tostring(name) end
end
Library.Executor = ExecutorName

local FS = {
	ok = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
		and type(isfolder) == "function" and type(makefolder) == "function",
	list = type(listfiles) == "function",
}
local MemoryConfigs = {}

Library.Compat = {
	Executor = ExecutorName,
	Files = FS.ok,
	Gethui = type(gethui) == "function",
	Cloneref = type(cloneref) == "function",
}

-- Try every sensible GUI parent until one actually accepts the ScreenGui.
local function ParentCandidates()
	local list = {}
	if type(gethui) == "function" then
		table.insert(list, function() return gethui() end)
	end
	table.insert(list, function()
		local c = Service("CoreGui")
		local _ = c:GetChildren() -- throws if the environment cannot touch CoreGui
		return c
	end)
	table.insert(list, function() return Players.LocalPlayer:WaitForChild("PlayerGui", 5) end)
	return list
end

local function KillOld(name)
	for _, get in ipairs(ParentCandidates()) do
		local ok, parent = pcall(get)
		if ok and parent then
			pcall(function()
				local old = parent:FindFirstChild(name)
				if old then old:Destroy() end
			end)
		end
	end
end

local function MountGui(gui)
	for _, get in ipairs(ParentCandidates()) do
		local ok, parent = pcall(get)
		if ok and parent then
			local ok2 = pcall(function() gui.Parent = parent end)
			if ok2 and gui.Parent == parent then return parent end
		end
	end
	return nil
end

--============================================================================
-- Themes
--============================================================================
-- Keys: Background, Sidebar, Section, Element, ElementHover, ElementActive,
--       Stroke, Text, SubText, Accent, Off
local Themes = {
	Dark = {
		Background = rgb(22, 22, 27), Sidebar = rgb(16, 16, 20), Section = rgb(28, 28, 34),
		Element = rgb(38, 38, 46), ElementHover = rgb(48, 48, 58), ElementActive = rgb(60, 60, 74),
		Stroke = rgb(50, 50, 62), Text = rgb(244, 244, 250), SubText = rgb(150, 150, 166),
		Accent = rgb(110, 118, 255), Off = rgb(68, 68, 82),
	},
	Light = {
		Background = rgb(243, 244, 248), Sidebar = rgb(230, 233, 240), Section = rgb(250, 251, 253),
		Element = rgb(255, 255, 255), ElementHover = rgb(239, 242, 247), ElementActive = rgb(226, 230, 238),
		Stroke = rgb(212, 217, 226), Text = rgb(28, 30, 38), SubText = rgb(108, 114, 130),
		Accent = rgb(79, 70, 229), Off = rgb(190, 195, 206),
	},
	Discord = {
		Background = rgb(54, 57, 63), Sidebar = rgb(47, 49, 54), Section = rgb(50, 53, 59),
		Element = rgb(64, 68, 75), ElementHover = rgb(74, 78, 86), ElementActive = rgb(84, 88, 97),
		Stroke = rgb(32, 34, 37), Text = rgb(255, 255, 255), SubText = rgb(185, 187, 190),
		Accent = rgb(88, 101, 242), Off = rgb(114, 118, 125),
	},
	Red = {
		Background = rgb(28, 20, 22), Sidebar = rgb(20, 14, 16), Section = rgb(36, 25, 28),
		Element = rgb(50, 34, 38), ElementHover = rgb(64, 42, 48), ElementActive = rgb(78, 50, 58),
		Stroke = rgb(72, 44, 50), Text = rgb(250, 240, 240), SubText = rgb(170, 140, 146),
		Accent = rgb(239, 68, 68), Off = rgb(90, 64, 70),
	},
	Ocean = {
		Background = rgb(15, 23, 32), Sidebar = rgb(11, 18, 26), Section = rgb(20, 30, 42),
		Element = rgb(28, 41, 56), ElementHover = rgb(36, 52, 70), ElementActive = rgb(45, 64, 86),
		Stroke = rgb(38, 54, 72), Text = rgb(232, 242, 250), SubText = rgb(130, 155, 178),
		Accent = rgb(56, 189, 248), Off = rgb(62, 80, 100),
	},
	Midnight = {
		Background = rgb(10, 10, 15), Sidebar = rgb(6, 6, 10), Section = rgb(16, 16, 24),
		Element = rgb(24, 24, 36), ElementHover = rgb(32, 32, 48), ElementActive = rgb(42, 42, 62),
		Stroke = rgb(36, 36, 52), Text = rgb(240, 240, 250), SubText = rgb(130, 130, 160),
		Accent = rgb(168, 85, 247), Off = rgb(60, 60, 80),
	},
	Rose = {
		Background = rgb(30, 22, 28), Sidebar = rgb(22, 15, 21), Section = rgb(38, 28, 36),
		Element = rgb(52, 38, 50), ElementHover = rgb(66, 48, 63), ElementActive = rgb(80, 58, 76),
		Stroke = rgb(74, 52, 70), Text = rgb(252, 238, 248), SubText = rgb(176, 140, 168),
		Accent = rgb(244, 114, 182), Off = rgb(96, 70, 92),
	},
}
Library.Themes = Themes

local NotifyColors = {
	Success = rgb(74, 222, 128),
	Warning = rgb(250, 204, 21),
	Error   = rgb(248, 113, 113),
}

--============================================================================
-- Helpers
--============================================================================
local function Merge(base, extra)
	local out = {}
	for k, v in pairs(base) do out[k] = v end
	for k, v in pairs(extra or {}) do out[k] = v end
	return out
end

local function ResolveTheme(theme)
	if type(theme) == "table" then return Merge(Themes.Dark, theme) end
	return Themes[theme or "Dark"] or Themes.Dark
end

local function Safe(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then warn("[KwargsUI] callback error: " .. tostring(err)) end
end

local function Tween(inst, time, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function New(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	if parent then inst.Parent = parent end
	return inst
end

local function Corner(parent, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function Pad(parent, l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0),
		Parent = parent,
	})
end

local function IsPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

-- Lets every method work with both `obj:Method()` and `obj.Method()`.
local function Methods(obj, methods)
	for name, fn in pairs(methods) do
		obj[name] = function(a, ...)
			if a == obj then return fn(...) end
			return fn(a, ...)
		end
	end
	return obj
end

local function HexOf(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function ColorFromHex(str)
	local t = tostring(str):match("^#?(%x%x%x%x%x%x)$")
	if not t then return nil end
	return rgb(tonumber(t:sub(1, 2), 16), tonumber(t:sub(3, 4), 16), tonumber(t:sub(5, 6), 16))
end

-- Material-style click ripple, clipped to the host element.
local function Ripple(win, host, input)
	if not win.Animated then return end
	local scale = win._Scale.Scale
	if scale <= 0 then return end
	local rel = (Vector2.new(input.Position.X, input.Position.Y) - host.AbsolutePosition) / scale
	local size = math.max(host.AbsoluteSize.X, host.AbsoluteSize.Y) / scale * 2.2
	local r = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(rel.X, rel.Y), Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = win.Theme.Accent, BackgroundTransparency = 0.72, BorderSizePixel = 0, Parent = host,
	})
	New("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = r })
	Tween(r, 0.55, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 })
	task.delay(0.6, function() r:Destroy() end)
end

local function AuroraSequence(theme)
	local a = theme.Accent
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, a),
		ColorSequenceKeypoint.new(0.25, theme.Stroke),
		ColorSequenceKeypoint.new(0.5, a:Lerp(WHITE, 0.25)),
		ColorSequenceKeypoint.new(0.75, theme.Stroke),
		ColorSequenceKeypoint.new(1, a),
	})
end

local function TitleSequence(theme)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.Accent:Lerp(WHITE, 0.15)),
		ColorSequenceKeypoint.new(0.5, theme.Text),
		ColorSequenceKeypoint.new(1, theme.Accent:Lerp(WHITE, 0.15)),
	})
end

--============================================================================
-- Classes
--============================================================================
local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section

function Library:AddTheme(name, theme)
	Themes[name] = Merge(Themes.Dark, theme)
end

-- Window core ---------------------------------------------------------------------------
function Window:Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self._conns, c)
	return c
end

function Window:Bind(inst, prop, key)
	inst[prop] = self.Theme[key]
	table.insert(self._bound, { inst, prop, key })
	return inst
end

function Window:OnTheme(inst, fn)
	table.insert(self._refreshers, { inst, fn })
end

function Window:Stroke(inst, key)
	local s = New("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inst })
	self:Bind(s, "Color", key or "Stroke")
	return s
end

function Window:SetTheme(theme)
	if type(theme) == "string" and not Themes[theme] then return false end
	self.Theme = ResolveTheme(theme)

	local bound = {}
	for _, b in ipairs(self._bound) do
		if b[1]:IsDescendantOf(self.Gui) then
			Tween(b[1], 0.3, { [b[2]] = self.Theme[b[3]] })
			table.insert(bound, b)
		end
	end
	self._bound = bound

	local refreshers = {}
	for _, r in ipairs(self._refreshers) do
		if r[1]:IsDescendantOf(self.Gui) then
			Safe(r[2])
			table.insert(refreshers, r)
		end
	end
	self._refreshers = refreshers
	return true
end

function Window:SetVisible(visible)
	self.Visible = visible
	if visible then
		self.Main.Visible = true
		Tween(self.Main, 0.25, { GroupTransparency = 0 })
		Tween(self._Scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		Tween(self.Main, 0.18, { GroupTransparency = 1 })
		Tween(self._Scale, 0.18, { Scale = 0.92 })
		task.delay(0.19, function()
			if not self.Visible and self.Main then self.Main.Visible = false end
		end)
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}
	Tween(self.Main, 0.2, { GroupTransparency = 1 })
	Tween(self._Scale, 0.2, { Scale = 0.88 })
	task.delay(0.22, function() self.Gui:Destroy() end)
end

function Window:Quit(o)
	o = o or {}
	local message = o.Message or "Goodbye..."
	local length = o.Length or 1

	local overlay = New("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 100, Parent = self.Main,
	})
	self:Bind(overlay, "BackgroundColor3", "Background")
	local label = New("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 101,
		Font = Enum.Font.GothamBold, TextSize = 20, Text = message, Parent = overlay,
	})
	self:Bind(label, "TextColor3", "Text")
	local labelScale = New("UIScale", { Scale = 0.85, Parent = label })
	Tween(overlay, 0.3, { BackgroundTransparency = 0 })
	Tween(label, 0.3, { TextTransparency = 0 })
	Tween(labelScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(length + 0.3, function() self:Destroy() end)
end

function Window:Notify(o)
	o = o or {}
	local duration = o.Duration or 4
	local accent = NotifyColors[o.Type] or self.Theme.Accent

	local wrap = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self._Notifs,
	})
	local card = New("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(1, 70, 0, 0),
		GroupTransparency = 1, BorderSizePixel = 0, Parent = wrap,
	})
	self:Bind(card, "BackgroundColor3", "Element")
	Corner(card, 10)
	self:Stroke(card)
	New("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = card })

	local inner = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
	})
	Pad(inner, 14, 10, 12, 10)
	New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })

	local title = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 1, Font = Enum.Font.GothamBold,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = o.Title or "Notification", Parent = inner,
	})
	self:Bind(title, "TextColor3", "Text")

	if o.Content and o.Content ~= "" then
		local content = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			LayoutOrder = 2, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			Text = tostring(o.Content), Parent = inner,
		})
		self:Bind(content, "TextColor3", "SubText")
	end

	local track = New("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, LayoutOrder = 3, Parent = inner })
	local fill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = track })
	Corner(fill, 1)

	local dismissed = false
	local function dismiss()
		if dismissed then return end
		dismissed = true
		Tween(card, 0.25, { Position = UDim2.new(1, 70, 0, 0), GroupTransparency = 1 })
		task.delay(0.28, function() wrap:Destroy() end)
	end

	Tween(card, 0.4, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, Enum.EasingStyle.Back)
	Tween(fill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)
	task.delay(duration, dismiss)
	card.InputBegan:Connect(function(input)
		if IsPointer(input) then dismiss() end
	end)

	return { Dismiss = dismiss }
end

-- Config system (files when available, in-memory otherwise) ---------------------------------------------
function Window:_ConfigPath(name)
	return self.ConfigFolder .. "/" .. tostring(name or "default") .. ".json"
end

function Window:SaveConfig(name)
	local data = {}
	for flag, obj in pairs(self.Flags) do
		local ok, value = pcall(obj._save)
		if ok then data[flag] = value end
	end
	local json = HttpService:JSONEncode(data)
	name = tostring(name or "default")

	if FS.ok then
		local ok = pcall(function()
			if not isfolder(self.ConfigFolder) then makefolder(self.ConfigFolder) end
			writefile(self:_ConfigPath(name), json)
		end)
		if ok then return true end
	end
	MemoryConfigs[self.ConfigFolder .. "/" .. name] = json
	return true, "Saved in memory (this executor has no file access)."
end

function Window:LoadConfig(name)
	name = tostring(name or "default")
	local json
	if FS.ok then
		pcall(function()
			local path = self:_ConfigPath(name)
			if isfile(path) then json = readfile(path) end
		end)
	end
	json = json or MemoryConfigs[self.ConfigFolder .. "/" .. name]
	if not json then return false, "Config not found." end

	local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok or type(data) ~= "table" then return false, "Config is corrupted." end
	for flag, value in pairs(data) do
		local obj = self.Flags[flag]
		if obj then Safe(obj._load, value) end
	end
	return true
end

function Window:ListConfigs()
	local out, seen = {}, {}
	if FS.ok and FS.list then
		pcall(function()
			if isfolder(self.ConfigFolder) then
				for _, file in ipairs(listfiles(self.ConfigFolder)) do
					local n = tostring(file):match("([^/\\]+)%.json$")
					if n and not seen[n] then seen[n] = true table.insert(out, n) end
				end
			end
		end)
	end
	local prefix = self.ConfigFolder .. "/"
	for key in pairs(MemoryConfigs) do
		if key:sub(1, #prefix) == prefix then
			local n = key:sub(#prefix + 1)
			if not seen[n] then seen[n] = true table.insert(out, n) end
		end
	end
	return out
end

--============================================================================
-- Library:Create
--============================================================================
function Library:Create(opts)
	opts = opts or {}
	local self = setmetatable({}, Window)

	self.Name = opts.Name or "UI Library"
	self.Theme = ResolveTheme(opts.Theme)
	self.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightControl
	self.ConfigFolder = opts.ConfigFolder or "KwargsUI"
	self.Animated = opts.Animated ~= false
	self.Flags, self.Tabs = {}, {}
	self._bound, self._refreshers, self._conns = {}, {}, {}
	self.Visible = true

	local guiName = "KwargsUI_" .. (self.Name:gsub("%s+", ""))
	KillOld(guiName)

	local size = opts.Size or UDim2.fromOffset(580, 400)
	local camera = Service("Workspace").CurrentCamera
	if camera then
		local vp = camera.ViewportSize
		size = UDim2.fromOffset(
			math.max(math.min(size.X.Offset, vp.X - 40), 300),
			math.max(math.min(size.Y.Offset, vp.Y - 100), 220)
		)
	end

	self.Gui = New("ScreenGui", {
		Name = guiName, ResetOnSpawn = false, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	if not MountGui(self.Gui) then
		self.Gui:Destroy()
		error("[KwargsUI] Could not find a valid GUI parent in this environment.")
	end

	-- Main window (CanvasGroup so the whole UI can fade as one) ---------------------------------------
	local Main = New("CanvasGroup", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size,
		BorderSizePixel = 0, GroupTransparency = 1, Parent = self.Gui,
	})
	Main.BackgroundTransparency = 1
	Corner(Main, 14)
	self.Main = Main

	-- NOTE: a UIGradient on a CanvasGroup tints ALL its content, so the gradient lives on a child frame.
	local Bg = New("Frame", { Name = "Bg", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 0, Parent = Main })
	Corner(Bg, 14)
	local BgGradient = New("UIGradient", { Rotation = 120, Parent = Bg })
	local function paintBackground()
		BgGradient.Color = ColorSequence.new(self.Theme.Background, self.Theme.Background:Lerp(self.Theme.Sidebar, 0.7))
	end
	paintBackground()
	self:OnTheme(Bg, paintBackground)

	local Border = New("UIStroke", { Thickness = 1.6, Color = WHITE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Main })
	local BorderGrad = New("UIGradient", { Parent = Border })
	local function paintBorder() BorderGrad.Color = AuroraSequence(self.Theme) end
	paintBorder()
	self:OnTheme(Border, paintBorder)

	self._Scale = New("UIScale", { Scale = 0.92, Parent = Main })
	Tween(Main, 0.35, { GroupTransparency = 0 })
	Tween(self._Scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)

	-- Topbar ------------------------------------------------------------------------------------------
	local Topbar = New("Frame", { Name = "Topbar", Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = Main })

	local Dot = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.fromOffset(9, 9),
		BorderSizePixel = 0, Parent = Topbar,
	})
	self:Bind(Dot, "BackgroundColor3", "Accent")
	Corner(Dot, 5)
	local DotGlow = New("UIStroke", { Thickness = 3, Transparency = 0.75, Parent = Dot })
	self:Bind(DotGlow, "Color", "Accent")

	local Title = New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -120, 1, 0),
		Font = Enum.Font.GothamBlack, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = WHITE, Text = self.Name, Parent = Topbar,
	})
	local TitleGrad = New("UIGradient", { Parent = Title })
	local function paintTitle() TitleGrad.Color = TitleSequence(self.Theme) end
	paintTitle()
	self:OnTheme(Title, paintTitle)

	local Line = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0, Parent = Topbar,
	})
	self:Bind(Line, "BackgroundColor3", "Accent")
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Line,
	})

	local function TopButton(text, offset, hoverColor)
		local b = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offset, 0.5, 0), Size = UDim2.fromOffset(28, 28),
			AutoButtonColor = false, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18,
			Text = text, Parent = Topbar,
		})
		self:Bind(b, "TextColor3", "SubText")
		Corner(b, 8)
		b.MouseEnter:Connect(function()
			Tween(b, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = hoverColor or self.Theme.ElementHover, TextColor3 = hoverColor and WHITE or self.Theme.Text })
		end)
		b.MouseLeave:Connect(function()
			Tween(b, 0.15, { BackgroundTransparency = 1, TextColor3 = self.Theme.SubText })
		end)
		return b
	end
	TopButton("×", -12, rgb(239, 68, 68)).MouseButton1Click:Connect(function()
		self:Quit({ Message = opts.QuitMessage or "Goodbye...", Length = 0.6 })
	end)
	TopButton("–", -44).MouseButton1Click:Connect(function() self:SetVisible(false) end)

	-- Dragging (mouse + touch)
	local dragging, dragStart, startPos
	Topbar.InputBegan:Connect(function(input)
		if IsPointer(input) then
			dragging, dragStart, startPos = true, input.Position, Main.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
				end
			end)
		end
	end)
	self:Connect(UserInputService.InputChanged, function(input)
		if dragging and IsMove(input) then
			local d = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	-- Tab bar --------------------------------------------------------------------------------------------
	local TabBar = New("Frame", {
		Name = "TabBar", Position = UDim2.fromOffset(0, 44), Size = UDim2.new(0, 148, 1, -44),
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = Main,
	})
	self:Bind(TabBar, "BackgroundColor3", "Sidebar")

	self._TabList = New("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -26), ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), Parent = TabBar,
	})

	self._Pill = New("Frame", {
		Name = "Pill", Position = UDim2.new(0, 8, 0, 10), Size = UDim2.new(1, -16, 0, 32), BorderSizePixel = 0,
		Visible = false, ZIndex = 1, Parent = self._TabList,
	})
	self:Bind(self._Pill, "BackgroundColor3", "Element")
	Corner(self._Pill, 9)
	local PillStroke = New("UIStroke", { Thickness = 1, Transparency = 0.55, Parent = self._Pill })
	self:Bind(PillStroke, "Color", "Accent")
	local PillBar = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 5, 0.5, 0), Size = UDim2.fromOffset(3, 14),
		BorderSizePixel = 0, Parent = self._Pill,
	})
	self:Bind(PillBar, "BackgroundColor3", "Accent")
	Corner(PillBar, 2)

	local Footer = New("TextLabel", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10, TextTransparency = 0.35,
		Text = "v" .. Library.Version .. "  ·  " .. ExecutorName, Parent = TabBar,
	})
	self:Bind(Footer, "TextColor3", "SubText")

	self._Pages = New("Frame", {
		Name = "Pages", BackgroundTransparency = 1, Position = UDim2.fromOffset(148, 44),
		Size = UDim2.new(1, -148, 1, -44), ClipsDescendants = true, Parent = Main,
	})

	-- Notifications --------------------------------------------------------------------------------------
	self._Notifs = New("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.new(0, 290, 1, -24), BackgroundTransparency = 1, Parent = self.Gui,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder, Parent = self._Notifs,
	})

	-- Mobile launcher --------------------------------------------------------------------------------------
	if opts.Launcher ~= false and UserInputService.TouchEnabled then
		local L = New("TextButton", {
			Name = "Launcher", Position = UDim2.new(0, 12, 0.5, -21), Size = UDim2.fromOffset(42, 42),
			AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 20, Text = "≡", Parent = self.Gui,
		})
		self:Bind(L, "BackgroundColor3", "Element")
		self:Bind(L, "TextColor3", "Text")
		Corner(L, 21)
		self:Stroke(L)
		L.MouseButton1Click:Connect(function() self:Toggle() end)
	end

	-- Toggle key + ambient animation ------------------------------------------------------------------------
	self:Connect(UserInputService.InputBegan, function(input, processed)
		if processed or self._listening then return end
		if input.KeyCode == self.ToggleKey then self:Toggle() end
	end)

	if self.Animated then
		local t = 0
		self:Connect(RunService.Heartbeat, function(dt)
			if not self.Visible then return end
			t = t + dt
			BorderGrad.Rotation = (t * 40) % 360
			TitleGrad.Offset = Vector2.new(math.sin(t * 1.2) * 0.35, 0)
			DotGlow.Transparency = 0.7 + math.sin(t * 2.4) * 0.15
		end)
	end

	return self
end

--============================================================================
-- Tab
--============================================================================
function Window:Tab(o)
	o = o or {}
	local win = self
	local tab = setmetatable({ Window = win, Name = o.Name or "Tab", Sections = {} }, Tab)
	tab.Index = #win.Tabs + 1
	local y = 10 + (tab.Index - 1) * 36

	local Btn = New("TextButton", {
		Name = tab.Name, Position = UDim2.new(0, 8, 0, y), Size = UDim2.new(1, -16, 0, 32), AutoButtonColor = false,
		BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", ZIndex = 2, Parent = win._TabList,
	})
	win._TabList.CanvasSize = UDim2.new(0, 0, 0, y + 32 + 10)

	local Label = New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0),
		Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = tab.Name, Parent = Btn,
	})

	local Group = New("CanvasGroup", {
		Name = tab.Name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		Visible = false, Parent = win._Pages,
	})
	local Page = New("ScrollingFrame", {
		Name = "Page", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = Group,
	})
	win:Bind(Page, "ScrollBarImageColor3", "SubText")
	New("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = Page })
	Pad(Page, 10, 10, 12, 10)

	tab.Page, tab.Group, tab.Button = Page, Group, Btn

	local function render()
		local selected = win._selected == tab
		Tween(Label, 0.2, {
			TextColor3 = selected and win.Theme.Text or win.Theme.SubText,
			Position = UDim2.fromOffset(selected and 18 or 14, 0),
		})
	end
	tab._render = render
	win:OnTheme(Btn, render)

	function tab:Select()
		if win._selected == tab then return end
		local first = win._selected == nil
		win._selected = tab
		for _, t in ipairs(win.Tabs) do
			if t ~= tab then t.Group.Visible = false end
			t._render()
		end

		-- sliding pill
		local pos = UDim2.new(0, 8, 0, 10 + (tab.Index - 1) * 36)
		win._Pill.Visible = true
		if first or not win.Animated then
			win._Pill.Position = pos
		else
			Tween(win._Pill, 0.4, { Position = pos }, Enum.EasingStyle.Quint)
		end

		-- page transition (fade + slide up)
		Group.Visible = true
		if first or not win.Animated then
			Group.GroupTransparency = 0
			Page.Position = UDim2.new()
		else
			Group.GroupTransparency = 1
			Page.Position = UDim2.fromOffset(0, 16)
			Tween(Group, 0.3, { GroupTransparency = 0 })
			Tween(Page, 0.4, { Position = UDim2.new() }, Enum.EasingStyle.Quint)
		end
	end

	Btn.MouseEnter:Connect(function()
		if win._selected ~= tab then
			Tween(Label, 0.15, { TextColor3 = win.Theme.Text, Position = UDim2.fromOffset(17, 0) })
		end
	end)
	Btn.MouseLeave:Connect(function()
		if win._selected ~= tab then render() end
	end)
	Btn.MouseButton1Click:Connect(function() tab:Select() end)

	table.insert(win.Tabs, tab)
	if #win.Tabs == 1 then tab:Select() else render() end
	return tab
end

--============================================================================
-- Section (a.k.a. Divider)
--============================================================================
function Tab:Divider(o)
	if type(o) == "string" then o = { Name = o } end
	o = o or {}
	local win = self.Window
	local sec = setmetatable({ Window = win, Tab = self, Name = o.Name or "", _order = 0 }, Section)
	table.insert(self.Sections, sec)

	local Frame = New("Frame", {
		Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0, LayoutOrder = #self.Sections, Parent = self.Page,
	})
	win:Bind(Frame, "BackgroundColor3", "Section")
	Corner(Frame, 10)
	win:Stroke(Frame)
	Pad(Frame, 8, 8, 8, 8)
	New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Frame })

	if sec.Name ~= "" then
		local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 0, Parent = Frame })
		local Bar = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(3, 11),
			BorderSizePixel = 0, Parent = Row,
		})
		win:Bind(Bar, "BackgroundColor3", "Accent")
		Corner(Bar, 2)
		local L = New("TextLabel", {
			Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0), BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			Text = sec.Name:upper(), Parent = Row,
		})
		win:Bind(L, "TextColor3", "SubText")
	end

	sec.Container = Frame
	sec.Instance = Frame
	return sec
end
Tab.Section = Tab.Divider

-- Shared element scaffold ---------------------------------------------------------------------------------
function Section:_Element(o, rightWidth)
	local win = self.Window
	local hasDesc = type(o.Description) == "string" and o.Description ~= ""
	rightWidth = rightWidth or 80
	self._order = self._order + 1

	local Holder = New("Frame", {
		Name = tostring(o.Name), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0, LayoutOrder = self._order, Parent = self.Container,
	})
	win:Bind(Holder, "BackgroundColor3", "Element")
	Corner(Holder, 8)
	local Glow = New("UIStroke", { Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Holder })
	win:Bind(Glow, "Color", "Accent")
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Holder })

	local Header = New("TextButton", {
		Name = "Header", Size = UDim2.new(1, 0, 0, hasDesc and 48 or 34), BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "", ClipsDescendants = true, LayoutOrder = 1, Parent = Holder,
	})
	Corner(Header, 8)

	local Title = New("TextLabel", {
		Name = "Title", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, hasDesc and 7 or 0),
		Size = hasDesc and UDim2.new(1, -(rightWidth + 10), 0, 16) or UDim2.new(1, -(rightWidth + 10), 1, 0),
		Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(o.Name), Parent = Header,
	})
	win:Bind(Title, "TextColor3", "Text")

	local Desc
	if hasDesc then
		Desc = New("TextLabel", {
			Name = "Description", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 25),
			Size = UDim2.new(1, -(rightWidth + 10), 0, 16), Font = Enum.Font.Gotham, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = o.Description, Parent = Header,
		})
		win:Bind(Desc, "TextColor3", "SubText")
	end

	local function paint(key, glow)
		Tween(Holder, 0.15, { BackgroundColor3 = win.Theme[key] })
		Tween(Glow, 0.2, { Transparency = glow })
	end
	Header.MouseEnter:Connect(function() paint("ElementHover", 0.55) end)
	Header.MouseLeave:Connect(function() paint("Element", 1) end)
	Header.MouseButton1Down:Connect(function() paint("ElementActive", 0.3) end)
	Header.MouseButton1Up:Connect(function() paint("ElementHover", 0.55) end)
	Header.InputBegan:Connect(function(input)
		if IsPointer(input) then Ripple(win, Header, input) end
	end)

	return Holder, Header, Title, Desc
end

function Section:_Finish(obj, o, Holder, Title, Desc)
	obj.Instance = Holder
	local hide = function() Holder.Visible = false end
	local show = function() Holder.Visible = true end
	Methods(obj, {
		SetName = function(t) Title.Text = tostring(t) end,
		SetDescription = function(t) if Desc then Desc.Text = tostring(t) end end,
		Hide = hide, HideElement = hide,
		Show = show, ShowElement = show,
		Destroy = function() Holder:Destroy() end,
	})
	if o.Flag then self.Window.Flags[o.Flag] = obj end
	return obj
end

--============================================================================
-- Elements
--============================================================================

-- Button ---------------------------------------------------------------------------------------------------
function Section:Button(o)
	o = o or {}
	o.Name = o.Name or "Button"
	local win = self.Window
	local callback = o.Callback or function() end
	local Holder, Header, Title, Desc = self:_Element(o, 40)

	local Chevron = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18, Text = "›", Parent = Header,
	})
	win:Bind(Chevron, "TextColor3", "SubText")
	Header.MouseEnter:Connect(function()
		Tween(Chevron, 0.2, { Position = UDim2.new(1, -6, 0.5, 0) }, Enum.EasingStyle.Back)
		Tween(Chevron, 0.2, { TextColor3 = win.Theme.Accent })
	end)
	Header.MouseLeave:Connect(function()
		Tween(Chevron, 0.2, { Position = UDim2.new(1, -10, 0.5, 0), TextColor3 = win.Theme.SubText })
	end)

	local obj = {}
	local function fire() task.spawn(Safe, callback) end
	Header.MouseButton1Click:Connect(fire)
	Methods(obj, { Fire = fire })
	return self:_Finish(obj, o, Holder, Title, Desc)
end

-- Toggle ---------------------------------------------------------------------------------------------------
function Section:Toggle(o)
	o = o or {}
	o.Name = o.Name or "Toggle"
	local win = self.Window
	local callback = o.Callback or function() end
	local style = o.Style or 1
	local state = (o.State or o.Default) and true or false
	local Holder, Header, Title, Desc = self:_Element(o, 60)

	local Track = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), BorderSizePixel = 0,
		Size = style == 2 and UDim2.fromOffset(22, 22) or UDim2.fromOffset(38, 20), Parent = Header,
	})
	Corner(Track, style == 2 and 6 or 10)
	local Glow = New("UIStroke", { Thickness = 2, Transparency = 1, Parent = Track })

	local Knob, Check
	if style == 2 then
		Check = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = Track,
		})
		Corner(Check, 3)
	else
		Knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = Track,
		})
		Corner(Knob, 7)
	end

	local function render(instant)
		local t = (instant or not win.Animated) and 0 or 0.25
		Tween(Track, t, { BackgroundColor3 = state and win.Theme.Accent or win.Theme.Off })
		Tween(Glow, t, { Transparency = state and 0.55 or 1, Color = win.Theme.Accent })
		if Knob then
			Tween(Knob, t, { Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, Enum.EasingStyle.Back)
			if t > 0 then
				-- squash & stretch
				Tween(Knob, 0.1, { Size = UDim2.fromOffset(20, 12) })
				task.delay(0.1, function() Tween(Knob, 0.2, { Size = UDim2.fromOffset(14, 14) }, Enum.EasingStyle.Back) end)
			end
		else
			Tween(Check, t, { Size = state and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
		end
	end
	render(true)
	win:OnTheme(Track, function() render(true) end)

	local obj = {}
	local function set(v, silent)
		v = v and true or false
		if v == state then return end
		state = v
		render()
		if not silent then task.spawn(Safe, callback, state) end
	end
	Header.MouseButton1Click:Connect(function() set(not state) end)

	Methods(obj, {
		Toggle = function() set(not state) end,
		Set = set, SetState = set,
		Get = function() return state end, GetState = function() return state end,
	})
	obj._save = function() return state end
	obj._load = function(v) set(v) end
	return self:_Finish(obj, o, Holder, Title, Desc)
end
Section.ToggleDropdown = Section.Toggle -- legacy alias

-- Slider ---------------------------------------------------------------------------------------------------
function Section:Slider(o)
	o = o or {}
	o.Name = o.Name or "Slider"
	local win = self.Window
	local callback = o.Callback or function() end
	local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
	local suffix = o.Suffix or ""
	local value = math.clamp(o.Default or min, min, max)
	local decimals = 0
	local frac = tostring(inc):match("%.(%d+)")
	if frac then decimals = #frac end

	local Holder, Header, Title, Desc = self:_Element(o, 80)
	local ValueLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(70, 20),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
		Parent = Header,
	})
	win:Bind(ValueLabel, "TextColor3", "Accent")

	local Body = New("Frame", { Name = "Body", Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 2, Parent = Holder })
	local Bar = New("Frame", { Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 6), BorderSizePixel = 0, Parent = Body })
	win:Bind(Bar, "BackgroundColor3", "Off")
	Corner(Bar, 3)
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, BackgroundColor3 = WHITE, Parent = Bar })
	Corner(Fill, 3)
	local FillGrad = New("UIGradient", { Parent = Fill })
	local function paintFill()
		FillGrad.Color = ColorSequence.new(win.Theme.Accent, win.Theme.Accent:Lerp(WHITE, 0.35))
	end
	paintFill()
	win:OnTheme(Fill, paintFill)

	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, Parent = Bar,
	})
	Corner(Knob, 8)
	local KnobGlow = New("UIStroke", { Thickness = 3, Transparency = 1, Parent = Knob })
	win:Bind(KnobGlow, "Color", "Accent")

	local function round(v)
		v = math.floor((v - min) / inc + 0.5) * inc + min
		v = math.clamp(v, min, max)
		return tonumber(string.format("%." .. decimals .. "f", v))
	end
	local function render(smooth)
		local a = (max == min) and 0 or (value - min) / (max - min)
		local t = (smooth and win.Animated) and 0.08 or 0
		Tween(Fill, t, { Size = UDim2.fromScale(a, 1) })
		Tween(Knob, t, { Position = UDim2.new(a, 0, 0.5, 0) })
		ValueLabel.Text = string.format("%." .. decimals .. "f", value) .. suffix
	end
	render(false)

	local obj = {}
	local function set(v, silent)
		v = round(tonumber(v) or value)
		if v == value then return end
		value = v
		render(true)
		if not silent then task.spawn(Safe, callback, value) end
	end

	local dragging = false
	local function grow(on)
		Tween(Knob, 0.18, { Size = on and UDim2.fromOffset(17, 17) or UDim2.fromOffset(12, 12) }, Enum.EasingStyle.Back)
		Tween(KnobGlow, 0.18, { Transparency = on and 0.6 or 1 })
	end
	local function fromX(x)
		local w = Bar.AbsoluteSize.X
		if w <= 0 then return end
		set(min + (max - min) * math.clamp((x - Bar.AbsolutePosition.X) / w, 0, 1))
	end
	Body.InputBegan:Connect(function(input)
		if IsPointer(input) then
			dragging = true
			grow(true)
			fromX(input.Position.X)
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					grow(false)
					c:Disconnect()
				end
			end)
		end
	end)
	win:Connect(UserInputService.InputChanged, function(input)
		if dragging and IsMove(input) then fromX(input.Position.X) end
	end)

	Methods(obj, { Set = set, SetValue = set, Get = function() return value end, GetValue = function() return value end })
	obj._save = function() return value end
	obj._load = function(v) set(v) end
	return self:_Finish(obj, o, Holder, Title, Desc)
end

-- Dropdown / SearchDropdown / multi-select -------------------------------------------------------------------
function Section:Dropdown(o)
	o = o or {}
	o.Name = o.Name or "Dropdown"
	local win = self.Window
	local multi = o.Multi == true
	local searchable = o.Searchable == true
	local callback = o.Callback or function() end
	local options = {}
	for _, v in ipairs(o.Options or {}) do table.insert(options, v) end

	local selected, single = {}, nil
	local buttons = {}
	local open = false
	local query = ""

	local Holder, Header, Title, Desc = self:_Element(o, 150)

	local ValueLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.5, 0), Size = UDim2.fromOffset(120, 20),
		BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "None", Parent = Header,
	})
	win:Bind(ValueLabel, "TextColor3", "SubText")
	local Arrow = New("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, Text = "▾", Parent = Header,
	})
	win:Bind(Arrow, "TextColor3", "SubText")

	local SearchWrap, SearchBox
	if searchable then
		SearchWrap = New("Frame", {
			Name = "Search", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true,
			Visible = false, LayoutOrder = 2, Parent = Holder,
		})
		SearchBox = New("TextBox", {
			Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 0, 26), BorderSizePixel = 0,
			ClearTextOnFocus = o.ClearText == true, PlaceholderText = o.Placeholder or "Search...", Text = "",
			Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = SearchWrap,
		})
		win:Bind(SearchBox, "BackgroundColor3", "Background")
		win:Bind(SearchBox, "TextColor3", "Text")
		win:Bind(SearchBox, "PlaceholderColor3", "SubText")
		Corner(SearchBox, 6)
		win:Stroke(SearchBox)
		Pad(SearchBox, 8, 0, 8, 0)
	end

	local List = New("ScrollingFrame", {
		Name = "List", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		Visible = false, LayoutOrder = 3, Parent = Holder,
	})
	win:Bind(List, "ScrollBarImageColor3", "SubText")
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = List })
	Pad(List, 6, 0, 6, 6)

	local function targetHeight()
		local n = 0
		for _, b in pairs(buttons) do
			if b.Button.Visible then n = n + 1 end
		end
		return math.min(n * 26 + 8, 160)
	end

	local function applyHeight()
		if open then Tween(List, 0.2, { Size = UDim2.new(1, 0, 0, targetHeight()) }, Enum.EasingStyle.Quint) end
	end

	local function setOpen(v)
		open = v
		Tween(Arrow, 0.25, { Rotation = v and 180 or 0 }, Enum.EasingStyle.Back)
		Tween(Arrow, 0.2, { TextColor3 = v and win.Theme.Accent or win.Theme.SubText })
		if v then
			List.Visible = true
			if SearchWrap then
				SearchWrap.Visible = true
				Tween(SearchWrap, 0.2, { Size = UDim2.new(1, 0, 0, 32) }, Enum.EasingStyle.Quint)
			end
			applyHeight()
			-- staggered option fade-in
			if win.Animated then
				local i = 0
				for _, opt in ipairs(options) do
					local b = buttons[opt]
					if b and b.Button.Visible and i < 8 then
						i = i + 1
						b.Label.TextTransparency = 1
						task.delay(i * 0.025, function()
							if open then Tween(b.Label, 0.2, { TextTransparency = 0 }) end
						end)
					end
				end
			end
		else
			Tween(List, 0.18, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint)
			if SearchWrap then Tween(SearchWrap, 0.18, { Size = UDim2.new(1, 0, 0, 0) }) end
			task.delay(0.2, function()
				if not open then
					List.Visible = false
					if SearchWrap then SearchWrap.Visible = false end
				end
			end)
		end
	end

	local function updateVisual()
		local names = {}
		for _, opt in ipairs(options) do
			local on = multi and selected[opt] or (not multi and single == opt)
			if on then table.insert(names, tostring(opt)) end
			local b = buttons[opt]
			if b then
				b.Label.TextColor3 = on and win.Theme.Accent or win.Theme.Text
				b.Tick.TextColor3 = win.Theme.Accent
				b.Tick.Visible = on and true or false
			end
		end
		ValueLabel.Text = #names > 0 and table.concat(names, ", ") or "None"
	end
	win:OnTheme(Holder, updateVisual)

	local function currentValue()
		if not multi then return single end
		local arr = {}
		for _, opt in ipairs(options) do
			if selected[opt] then table.insert(arr, opt) end
		end
		return arr
	end

	local function choose(opt)
		if multi then
			selected[opt] = (not selected[opt]) or nil
		else
			single = opt
			setOpen(false)
		end
		updateVisual()
		task.spawn(Safe, callback, currentValue())
	end

	local function applyFilter()
		local q = query:lower()
		for opt, b in pairs(buttons) do
			b.Button.Visible = q == "" or tostring(opt):lower():find(q, 1, true) ~= nil
		end
		applyHeight()
	end

	local function build()
		for _, b in pairs(buttons) do b.Button:Destroy() end
		buttons = {}
		for i, opt in ipairs(options) do
			local B = New("TextButton", {
				Name = tostring(opt), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, BorderSizePixel = 0,
				AutoButtonColor = false, Text = "", LayoutOrder = i, Parent = List,
			})
			Corner(B, 6)
			local L = New("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0),
				Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(opt), Parent = B,
			})
			local T = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, Text = "✓", Visible = false, Parent = B,
			})
			B.MouseEnter:Connect(function()
				Tween(B, 0.12, { BackgroundTransparency = 0, BackgroundColor3 = win.Theme.ElementActive })
				Tween(L, 0.15, { Position = UDim2.fromOffset(14, 0) })
			end)
			B.MouseLeave:Connect(function()
				Tween(B, 0.12, { BackgroundTransparency = 1 })
				Tween(L, 0.15, { Position = UDim2.fromOffset(10, 0) })
			end)
			B.MouseButton1Click:Connect(function() choose(opt) end)
			buttons[opt] = { Button = B, Label = L, Tick = T }
		end
		applyFilter()
		updateVisual()
	end

	if SearchBox then
		SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			query = SearchBox.Text
			applyFilter()
		end)
	end
	Header.MouseButton1Click:Connect(function() setOpen(not open) end)

	if multi then
		for _, v in ipairs(type(o.Default) == "table" and o.Default or {}) do selected[v] = true end
	elseif o.Default ~= nil then
		single = o.Default
	end
	build()

	local obj = {}
	local function set(v, silent)
		if multi then
			selected = {}
			for _, item in ipairs(type(v) == "table" and v or {}) do selected[item] = true end
		else
			single = v
		end
		updateVisual()
		if not silent then task.spawn(Safe, callback, currentValue()) end
	end
	Methods(obj, {
		Get = currentValue, GetValue = currentValue,
		Set = set, SetValue = set,
		AddOption = function(opt) table.insert(options, opt) build() end,
		RemoveOption = function(opt)
			for i, v in ipairs(options) do
				if v == opt then table.remove(options, i) break end
			end
			selected[opt] = nil
			if single == opt then single = nil end
			build()
		end,
		Refresh = function(newOptions)
			options = {}
			for _, v in ipairs(newOptions or {}) do table.insert(options, v) end
			selected, single = {}, nil
			build()
		end,
		Open = function() setOpen(true) end,
		Close = function() setOpen(false) end,
	})
	obj._save = currentValue
	obj._load = function(v) set(v) end
	return self:_Finish(obj, o, Holder, Title, Desc)
end

function Section:SearchDropdown(o)
	o = o or {}
	o.Searchable = true
	return self:Dropdown(o)
end

-- ColorPicker -------------------------------------------------------------------------------------------------
function Section:ColorPicker(o)
	o = o or {}
	o.Name = o.Name or "Color Picker"
	local win = self.Window
	local callback = o.Callback or function() end
	local color = o.Default or rgb(110, 118, 255)
	local h, s, v = color:ToHSV()
	local open = false

	local Holder, Header, Title, Desc = self:_Element(o, 60)
	local Swatch = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = color, BorderSizePixel = 0, Parent = Header,
	})
	Corner(Swatch, 6)
	win:Stroke(Swatch)

	local Body = New("Frame", {
		Name = "Body", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true,
		Visible = false, LayoutOrder = 2, Parent = Holder,
	})

	local SV = New("TextButton", {
		Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -46, 0, 100), AutoButtonColor = false,
		Text = "", BorderSizePixel = 0, Parent = Body,
	})
	Corner(SV, 6)
	local White = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = SV })
	Corner(White, 6)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = White })
	local Black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BorderSizePixel = 0, Parent = SV })
	Corner(Black, 6)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = Black })
	local SVCursor = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 3, Parent = SV,
	})
	Corner(SVCursor, 5)
	New("UIStroke", { Color = WHITE, Thickness = 2, Parent = SVCursor })

	local Hue = New("TextButton", {
		Position = UDim2.new(1, -28, 0, 4), Size = UDim2.fromOffset(18, 100), AutoButtonColor = false,
		Text = "", BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = Body,
	})
	Corner(Hue, 6)
	local stops = {}
	for i = 0, 6 do table.insert(stops, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i == 6 and 0 or i / 6, 1, 1))) end
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(stops), Parent = Hue })
	local HueCursor = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = WHITE,
		BorderSizePixel = 0, ZIndex = 3, Parent = Hue,
	})
	Corner(HueCursor, 2)
	New("UIStroke", { Color = rgb(0, 0, 0), Thickness = 1, Transparency = 0.5, Parent = HueCursor })

	local Hex = New("TextBox", {
		Position = UDim2.fromOffset(10, 110), Size = UDim2.new(1, -20, 0, 24), BorderSizePixel = 0, ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium, TextSize = 12, PlaceholderText = "#RRGGBB", Text = "", Parent = Body,
	})
	win:Bind(Hex, "BackgroundColor3", "Background")
	win:Bind(Hex, "TextColor3", "Text")
	win:Bind(Hex, "PlaceholderColor3", "SubText")
	Corner(Hex, 6)
	win:Stroke(Hex)

	local function render()
		color = Color3.fromHSV(h, s, v)
		Tween(Swatch, win.Animated and 0.1 or 0, { BackgroundColor3 = color })
		SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		HueCursor.Position = UDim2.new(0.5, 0, h, 0)
		Hex.Text = HexOf(color)
	end
	render()

	local function commit(silent)
		render()
		if not silent then task.spawn(Safe, callback, color) end
	end

	local mode
	local function track(input)
		if mode == "sv" then
			s = math.clamp((input.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((input.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
			commit()
		elseif mode == "hue" then
			h = math.clamp((input.Position.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 0.999)
			commit()
		end
	end
	local function begin(m)
		return function(input)
			if IsPointer(input) then
				mode = m
				track(input)
				local c
				c = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						mode = nil
						c:Disconnect()
					end
				end)
			end
		end
	end
	SV.InputBegan:Connect(begin("sv"))
	Hue.InputBegan:Connect(begin("hue"))
	win:Connect(UserInputService.InputChanged, function(input)
		if mode and IsMove(input) then track(input) end
	end)

	Hex.FocusLost:Connect(function()
		local c = ColorFromHex(Hex.Text)
		if c then
			h, s, v = c:ToHSV()
			commit()
		else
			render()
		end
	end)

	Header.MouseButton1Click:Connect(function()
		open = not open
		if open then
			Body.Visible = true
			Tween(Body, 0.28, { Size = UDim2.new(1, 0, 0, 142) }, Enum.EasingStyle.Quint)
		else
			Tween(Body, 0.2, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint)
			task.delay(0.22, function() if not open then Body.Visible = false end end)
		end
	end)

	local obj = {}
	local function set(c, silent)
		if typeof(c) == "string" then c = ColorFromHex(c) end
		if typeof(c) ~= "Color3" then return end
		h, s, v = c:ToHSV()
		commit(silent)
	end
	Methods(obj, {
		Set = set, SetColor = set,
		Get = function() return color end, GetColor = function() return color end,
	})
	obj._save = function() return HexOf(color) end
	obj._load = function(x) set(x) end
	return self:_Finish(obj, o, Holder, Title, Desc)
end
Section.ColourPicker = Section.ColorPicker

-- Box (text input) --------------------------------------------------------------------------------------------------
function Section:Box(o)
	o = o or {}
	o.Name = o.Name or "Box"
	local win = self.Window
	local callback = o.Callback or function() end
	local Holder, Header, Title, Desc = self:_Element(o, 150)

	local Input = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(130, 22),
		BorderSizePixel = 0, ClearTextOnFocus = o.ClearText == true, Font = Enum.Font.Gotham, TextSize = 12,
		PlaceholderText = o.Placeholder or "Type here...", Text = o.Default or "", TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Header,
	})
	win:Bind(Input, "BackgroundColor3", "Background")
	win:Bind(Input, "TextColor3", "Text")
	win:Bind(Input, "PlaceholderColor3", "SubText")
	Corner(Input, 6)
	local InputStroke = win:Stroke(Input)
	Pad(Input, 6, 0, 6, 0)

	Input.Focused:Connect(function() Tween(InputStroke, 0.2, { Color = win.Theme.Accent }) end)

	if o.Numeric then
		Input:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = Input.Text:gsub("[^%d%.%-]", "")
			if clean ~= Input.Text then Input.Text = clean end
		end)
	end

	Input.FocusLost:Connect(function(enterPressed)
		Tween(InputStroke, 0.2, { Color = win.Theme.Stroke })
		task.spawn(Safe, callback, Input.Text, enterPressed)
	end)

	local obj = {}
	local function set(t, silent)
		Input.Text = tostring(t)
		if not silent then task.spawn(Safe, callback, Input.Text, false) end
	end
	Methods(obj, {
		Set = set, SetText = set,
		Get = function() return Input.Text end, GetText = function() return Input.Text end,
	})
	obj._save = function() return Input.Text end
	obj._load = function(t) set(t) end
	return self:_Finish(obj, o, Holder, Title, Desc)
end

-- Keybind ----------------------------------------------------------------------------------------------------------------
function Section:Keybind(o)
	o = o or {}
	o.Name = o.Name or "Keybind"
	local win = self.Window
	local callback = o.Callback or function() end
	local changed = o.OnChange or function() end
	local key = o.Default
	if type(key) == "string" then
		local ok, kc = pcall(function() return Enum.KeyCode[key] end)
		key = ok and kc or nil
	end
	local listening = false

	local Holder, Header, Title, Desc = self:_Element(o, 110)
	local Btn = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(90, 22),
		AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 11, Parent = Header,
	})
	win:Bind(Btn, "BackgroundColor3", "Background")
	win:Bind(Btn, "TextColor3", "Text")
	Corner(Btn, 6)
	local BtnStroke = win:Stroke(Btn)

	local function label() Btn.Text = listening and "..." or (key and key.Name or "None") end
	label()

	local function startListening()
		listening = true
		win._listening = true
		label()
		Tween(BtnStroke, 0.2, { Color = win.Theme.Accent })
	end
	Btn.MouseButton1Click:Connect(startListening)
	Header.MouseButton1Click:Connect(startListening)

	win:Connect(UserInputService.InputBegan, function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				win._listening = false
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
					key = nil
				else
					key = input.KeyCode
				end
				label()
				Tween(BtnStroke, 0.2, { Color = win.Theme.Stroke })
				task.spawn(Safe, changed, key)
			end
			return
		end
		if not processed and key and input.KeyCode == key then
			task.spawn(Safe, callback, key)
			-- pulse feedback
			Tween(BtnStroke, 0.08, { Color = win.Theme.Accent })
			task.delay(0.12, function() Tween(BtnStroke, 0.25, { Color = win.Theme.Stroke }) end)
		end
	end)

	local obj = {}
	local function set(k)
		if type(k) == "string" then
			local ok, kc = pcall(function() return Enum.KeyCode[k] end)
			k = ok and kc or nil
		end
		key = k
		label()
	end
	Methods(obj, { Set = set, SetKey = set, Get = function() return key end, GetKey = function() return key end })
	obj._save = function() return key and key.Name or nil end
	obj._load = function(k) set(k) end
	return self:_Finish(obj, o, Holder, Title, Desc)
end

-- Label -------------------------------------------------------------------------------------------------------------------
function Section:Label(o)
	if type(o) == "string" then o = { Text = o } end
	o = o or {}
	local win = self.Window
	self._order = self._order + 1
	local L = New("TextLabel", {
		Name = "Label", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		TextWrapped = true, RichText = true, Font = Enum.Font.Gotham, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Text = o.Text or o.Name or "", LayoutOrder = self._order, Parent = self.Container,
	})
	win:Bind(L, "TextColor3", "SubText")
	Pad(L, 4, 2, 4, 2)

	local obj = { Instance = L }
	Methods(obj, {
		Set = function(t) L.Text = tostring(t) end,
		Hide = function() L.Visible = false end,
		Show = function() L.Visible = true end,
		Destroy = function() L:Destroy() end,
	})
	return obj
end

--============================================================================
-- Convenience: call elements straight on a Tab (creates an implicit section)
--============================================================================
for _, name in ipairs({ "Button", "Toggle", "ToggleDropdown", "Slider", "Dropdown", "SearchDropdown", "ColorPicker", "Box", "Keybind", "Label" }) do
	Tab[name] = function(self, o)
		if not self._implicit then self._implicit = self:Divider({ Name = "" }) end
		return self._implicit[name](self._implicit, o)
	end
end

return Library
