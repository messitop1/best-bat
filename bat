local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- ============ STATE ============
local State = {
	aimbotEnabled = false,
	autoSwing = true,
	aimbotSpeed = 58,
	vertSpeed = 52,
	dist = -2.8,
	height = 4.75,
	vOff = 1,
	turnSpeed = 285,
	maxTurnRate = 28,
	_target = nil,
	_lastScan = 0,
	_equipped = false,
	_conn = nil,
}

local Keys = {
	aimbot  = Enum.KeyCode.E,
	guiHide = Enum.KeyCode.LeftControl,
}

-- ============ HELPERS ============
local function getTarget()
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local now = tick()
	if now - State._lastScan <= 0.1 and State._target and State._target.Parent then
		local h = State._target.Parent:FindFirstChildOfClass("Humanoid")
		if h and h.Health > 0 then return State._target end
	end
	State._lastScan = now
	State._target = nil
	local closest, minDist = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and p.Character then
			local r = p.Character:FindFirstChild("HumanoidRootPart")
			local h = p.Character:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 then
				local d = (r.Position - root.Position).Magnitude
				if d < minDist then minDist = d; closest = r end
			end
		end
	end
	State._target = closest
	return State._target
end

local function stopAimbot()
	if State._conn then State._conn:Disconnect(); State._conn = nil end
	local char = LP.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.AutoRotate = true end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.AssemblyAngularVelocity = Vector3.zero
			root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.3
		end
	end
	State._equipped = false
end

local function startAimbot()
	if State._conn then return end
	State._conn = RunService.RenderStepped:Connect(function()
		if not State.aimbotEnabled then return end
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not hum then return end

		if not State._equipped then
			State._equipped = true
			if not char:FindFirstChild("Bat") then
				local bp = LP:FindFirstChildOfClass("Backpack")
				local bat = bp and bp:FindFirstChild("Bat")
				if bat then pcall(function() hum:EquipTool(bat) end) end
			end
		end

		local target = getTarget()
		if target then
			local vel = target.AssemblyLinearVelocity
			local aimPos = target.Position
				+ (vel * math.clamp(vel.Magnitude / 130, 0.05, 0.15))
				+ Vector3.new(0, State.vOff, 0)

			hum.AutoRotate = false
			local look = aimPos - root.Position
			local flat = Vector3.new(look.X, 0, look.Z)

			if look.Magnitude > 0.01 and flat.Magnitude > 0.01 then
				local yaw = math.deg(math.atan2(-flat.X, -flat.Z))
				local yawDelta = (yaw - root.Orientation.Y + 180) % 360 - 180
				local pitch = math.deg(math.atan2(look.Y, flat.Magnitude))
				local pitchDelta = (pitch - root.Orientation.X + 180) % 360 - 180
				local yawRate = math.clamp(math.rad(yawDelta) * State.turnSpeed, -State.maxTurnRate, State.maxTurnRate)
				local pitchRate = math.clamp(math.rad(pitchDelta) * State.turnSpeed, -State.maxTurnRate, State.maxTurnRate)
				local yawRad = math.rad(root.Orientation.Y)
				local right = Vector3.new(math.cos(yawRad), 0, -math.sin(yawRad))
				root.AssemblyAngularVelocity = Vector3.new(0, yawRate, 0) + (right * pitchRate)
			else
				root.AssemblyAngularVelocity = Vector3.zero
			end

			local dir = look.Magnitude > 0.01 and look.Unit or Vector3.zero
			local standPos = aimPos - (dir * State.dist) + Vector3.new(0, State.height, 0)
			local move = standPos - root.Position
			local hDir = Vector3.new(move.X, 0, move.Z)
			local hVel = hDir.Magnitude > 0.1 and hDir.Unit * State.aimbotSpeed or Vector3.zero
			local vVel = math.abs(move.Y) > 0.1
				and Vector3.new(0, math.sign(move.Y) * State.vertSpeed, 0)
				or Vector3.new(0, -2, 0)

			root.AssemblyLinearVelocity = hVel + vVel
			task.defer(function()
				if root and root.Parent then
					root.AssemblyLinearVelocity = hVel + vVel
				end
			end)

			if hDir.Magnitude > 0.5 then hum:Move(hDir.Unit, false) end

			if State.autoSwing then
				local bat = char:FindFirstChild("Bat")
				if bat and bat:IsA("Tool") then pcall(function() bat:Activate() end) end
			end
		else
			hum.AutoRotate = true
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end)
end

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "BatAimbotUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local C = {
	bg      = Color3.fromRGB(12, 12, 12),
	header  = Color3.fromRGB(8, 8, 8),
	card    = Color3.fromRGB(22, 22, 22),
	border  = Color3.fromRGB(38, 38, 38),
	accent  = Color3.fromRGB(210, 35, 35),
	text    = Color3.fromRGB(255, 255, 255),
	textSub = Color3.fromRGB(160, 160, 160),
	pillOn  = Color3.fromRGB(210, 35, 35),
	pillOff = Color3.fromRGB(40, 40, 40),
	dotOn   = Color3.fromRGB(255, 255, 255),
	dotOff  = Color3.fromRGB(140, 140, 140),
	keybind = Color3.fromRGB(28, 28, 28),
}

local W, H = 300, 260

local function mkCorner(p, r)
	local c = Instance.new("UICorner", p)
	c.CornerRadius = UDim.new(0, r or 6)
end
local function mkStroke(p, col, th)
	local s = Instance.new("UIStroke", p)
	s.Color = col or C.border
	s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local function getKeyName(kc)
	if kc == Enum.KeyCode.Unknown then return "—" end
	local n = kc.Name
	if n == "LeftControl" then return "CTRL" end
	if n == "LeftShift" then return "SHFT" end
	if n == "Space" then return "SPC" end
	return n:sub(1,4):upper()
end

-- Main frame
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
mkCorner(main, 10)
mkStroke(main, C.border, 1)

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = C.header
header.BorderSizePixel = 0
mkCorner(header, 10)
local headerFix = Instance.new("Frame", header)
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = C.header
headerFix.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, -50, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BAT AIMBOT"
titleLbl.TextColor3 = C.accent
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 15
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.TextYAlignment = Enum.TextYAlignment.Center

-- Drag
local dragging, dragStart, startPos2 = false, nil, nil
header.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = inp.Position; startPos2 = main.Position
		inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
UIS.InputChanged:Connect(function(inp)
	if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
		local d = inp.Position - dragStart
		main.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset + d.X, startPos2.Y.Scale, startPos2.Y.Offset + d.Y)
	end
end)

-- Scroll
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, 0, 1, -42)
scroll.Position = UDim2.new(0, 0, 0, 42)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = C.border
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local list = Instance.new("UIListLayout", scroll)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 4)
local pad = Instance.new("UIPadding", scroll)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)

local rowCount = 0
local function makeRow(rh)
	rowCount += 1
	local r = Instance.new("Frame", scroll)
	r.Size = UDim2.new(1, 0, 0, rh or 40)
	r.BackgroundColor3 = C.card
	r.BorderSizePixel = 0
	r.LayoutOrder = rowCount
	mkCorner(r, 6)
	return r
end

-- Keybind chip
local function makeKeybindChip(parent, keyRef, xPos)
	local chip = Instance.new("TextButton", parent)
	chip.Size = UDim2.new(0, 34, 0, 20)
	chip.Position = UDim2.new(0, xPos, 0.5, -10)
	chip.BackgroundColor3 = C.keybind
	chip.BorderSizePixel = 0
	chip.Text = getKeyName(Keys[keyRef])
	chip.TextColor3 = C.accent
	chip.Font = Enum.Font.GothamBold
	chip.TextSize = 9
	chip.ZIndex = 8
	mkCorner(chip, 5)
	mkStroke(chip, C.border, 1)

	local listening = false
	local lconn = nil
	chip.MouseButton1Click:Connect(function()
		if listening then
			listening = false
			if lconn then lconn:Disconnect(); lconn = nil end
			chip.Text = getKeyName(Keys[keyRef])
			chip.TextColor3 = C.accent
			return
		end
		listening = true
		chip.Text = "···"
		chip.TextColor3 = C.text
		lconn = UIS.InputBegan:Connect(function(inp)
			if not listening then return end
			if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
			listening = false
			lconn:Disconnect(); lconn = nil
			if inp.KeyCode == Enum.KeyCode.Escape then
				chip.Text = getKeyName(Keys[keyRef])
			else
				Keys[keyRef] = inp.KeyCode
				chip.Text = getKeyName(inp.KeyCode)
			end
			chip.TextColor3 = C.accent
		end)
	end)
end

-- Toggle row
local toggleRefs = {}
local function makeToggle(label, keyRef, default, onToggle)
	local row = makeRow(40)
	local lblX = 12
	if keyRef then
		makeKeybindChip(row, keyRef, lblX)
		lblX = lblX + 34 + 6
	end
	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(1, -(lblX + 58), 1, 0)
	lbl.Position = UDim2.new(0, lblX, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = C.text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local pill = Instance.new("Frame", row)
	pill.Size = UDim2.new(0, 40, 0, 22)
	pill.Position = UDim2.new(1, -52, 0.5, -11)
	pill.BackgroundColor3 = default and C.pillOn or C.pillOff
	pill.BorderSizePixel = 0
	mkCorner(pill, 12)

	local dot = Instance.new("Frame", pill)
	dot.Size = UDim2.new(0, 15, 0, 15)
	dot.Position = default and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5)
	dot.BackgroundColor3 = default and C.dotOn or C.dotOff
	dot.BorderSizePixel = 0
	mkCorner(dot, 8)

	local isOn = default or false
	local function setVal(on)
		isOn = on
		TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = on and C.pillOn or C.pillOff}):Play()
		TweenService:Create(dot, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
			Position = on and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5),
			BackgroundColor3 = on and C.dotOn or C.dotOff,
		}):Play()
	end
	local function toggle()
		isOn = not isOn; setVal(isOn)
		if onToggle then pcall(onToggle, isOn) end
	end
	local clk = Instance.new("TextButton", row)
	clk.Size = UDim2.new(1, -58, 1, 0)
	clk.Position = UDim2.new(0, lblX, 0, 0)
	clk.BackgroundTransparency = 1
	clk.Text = ""; clk.BorderSizePixel = 0
	clk.MouseButton1Click:Connect(toggle)
	local pClk = Instance.new("TextButton", pill)
	pClk.Size = UDim2.new(1, 0, 1, 0)
	pClk.BackgroundTransparency = 1
	pClk.Text = ""; pClk.BorderSizePixel = 0
	pClk.MouseButton1Click:Connect(toggle)
	return setVal
end

-- Speed row (+/-)
local function makeSpeedRow()
	local row = makeRow(40)
	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(0, 80, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "Speed"
	lbl.TextColor3 = C.text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local minusBtn = Instance.new("TextButton", row)
	minusBtn.Size = UDim2.new(0, 26, 0, 26)
	minusBtn.Position = UDim2.new(1, -132, 0.5, -13)
	minusBtn.BackgroundColor3 = C.keybind
	minusBtn.BorderSizePixel = 0
	minusBtn.Text = "−"
	minusBtn.TextColor3 = C.accent
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.TextSize = 14
	minusBtn.ZIndex = 7
	mkCorner(minusBtn, 6)
	mkStroke(minusBtn, C.border, 1)

	local vf = Instance.new("Frame", row)
	vf.Size = UDim2.new(0, 60, 0, 26)
	vf.Position = UDim2.new(1, -100, 0.5, -13)
	vf.BackgroundColor3 = C.bg
	vf.BorderSizePixel = 0
	vf.ZIndex = 6
	mkCorner(vf, 6)
	mkStroke(vf, C.accent, 1)

	local box = Instance.new("TextBox", vf)
	box.Size = UDim2.new(1, -8, 1, 0)
	box.Position = UDim2.new(0, 4, 0, 0)
	box.BackgroundTransparency = 1
	box.Text = tostring(State.aimbotSpeed)
	box.TextColor3 = C.accent
	box.Font = Enum.Font.GothamBold
	box.TextSize = 13
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Center
	box.ZIndex = 7

	local plusBtn = Instance.new("TextButton", row)
	plusBtn.Size = UDim2.new(0, 26, 0, 26)
	plusBtn.Position = UDim2.new(1, -34, 0.5, -13)
	plusBtn.BackgroundColor3 = C.keybind
	plusBtn.BorderSizePixel = 0
	plusBtn.Text = "+"
	plusBtn.TextColor3 = C.accent
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 14
	plusBtn.ZIndex = 7
	mkCorner(plusBtn, 6)
	mkStroke(plusBtn, C.border, 1)

	local function updateSpeed(n)
		n = math.clamp(math.floor(n), 1, 500)
		State.aimbotSpeed = n
		box.Text = tostring(n)
	end

	minusBtn.MouseButton1Click:Connect(function() updateSpeed(State.aimbotSpeed - 1) end)
	plusBtn.MouseButton1Click:Connect(function() updateSpeed(State.aimbotSpeed + 1) end)

	local function holdRepeat(btn, delta)
		local holding = false
		btn.InputBegan:Connect(function(inp)
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			holding = true
			task.delay(0.4, function()
				while holding do
					updateSpeed(State.aimbotSpeed + delta)
					task.wait(0.05)
				end
			end)
		end)
		btn.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then holding = false end
		end)
	end
	holdRepeat(minusBtn, -1)
	holdRepeat(plusBtn, 1)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then updateSpeed(n) else box.Text = tostring(State.aimbotSpeed) end
	end)
end

-- ====== BUILD ROWS ======
toggleRefs.aimbot = makeToggle("Bat Aimbot", "aimbot", false, function(on)
	State.aimbotEnabled = on
	if on then startAimbot() else stopAimbot() end
end)

makeSpeedRow()

do
	local row = makeRow(40)
	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "Hide GUI"
	lbl.TextColor3 = C.textSub
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	makeKeybindChip(row, "guiHide", 246)
end

-- ====== OPEN BTN ======
local openBtn = Instance.new("TextButton", gui)
openBtn.Size = UDim2.new(0, 60, 0, 28)
openBtn.Position = UDim2.new(0, 10, 0, 10)
openBtn.BackgroundColor3 = C.header
openBtn.BorderSizePixel = 0
openBtn.Text = "BAT"
openBtn.TextColor3 = C.accent
openBtn.Font = Enum.Font.GothamBlack
openBtn.TextSize = 13
openBtn.ZIndex = 100
mkCorner(openBtn, 8)
mkStroke(openBtn, C.border, 1)
openBtn.MouseButton1Click:Connect(function()
	main.Visible = not main.Visible
end)

-- ====== KEYBOARD ======
UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local kc = inp.KeyCode
	if kc == Enum.KeyCode.Unknown then return end
	if kc == Keys.aimbot then
		State.aimbotEnabled = not State.aimbotEnabled
		if toggleRefs.aimbot then toggleRefs.aimbot(State.aimbotEnabled) end
		if State.aimbotEnabled then startAimbot() else stopAimbot() end
	elseif kc == Keys.guiHide then
		main.Visible = not main.Visible
	end
end)

-- Entry animation
main.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, W, 0, H)
}):Play()
