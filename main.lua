--[[
    FlowUI (Flow.lua) — HeroUI-Inspired Liquid Glass Roblox UI Framework
    Version: 2.0.0 (Liquid Glass Edition)
    Features:
      - Ultra-Realistic Liquid Glass Engine:
          * Multi-layer translucent tint + frosted depth
          * Specular diagonal refraction UIGradient (mouse-reactive on hover)
          * Rim-lit 3D glass UIStroke with top-left highlight & bottom-right shadow
          * Ambient soft drop shadows & optional Lighting BlurEffect for modals
      - Unified Animation System (Flow.Anim):
          * Consistent HeroUI spring/quint micro-interactions across ALL 142 components
          * Hover rim glow, press compression (0.96x), click specular ripple
          * Sliding glass pill indicator for Tabs/Segment, smooth Modal/Drawer/Toast springs
      - Executor-Safe Mounting (gethui -> CoreGui -> PlayerGui)
]]

local Flow = {}
Flow.__index = Flow
Flow.Version = "2.0.0"

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

--// Executor-safe GUI parent resolver
local function getGuiParent()
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and typeof(res) == "Instance" then
            return res
        end
    end
    local okCore, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and coreGui then
        local testOk = pcall(function()
            local f = Instance.new("Folder")
            f.Parent = coreGui
            f:Destroy()
        end)
        if testOk then
            return coreGui
        end
    end
    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return game:GetService("StarterGui")
end

--// HeroUI v3 Semantic Color Tokens
Flow.Themes = {
    dark = {
        background = Color3.fromRGB(12, 13, 18),
        foreground = Color3.fromRGB(248, 250, 252),
        muted = Color3.fromRGB(161, 168, 184),
        surface = Color3.fromRGB(24, 26, 34),
        surfaceSecondary = Color3.fromRGB(36, 40, 52),
        overlay = Color3.fromRGB(20, 22, 30),
        border = Color3.fromRGB(90, 98, 120),
        divider = Color3.fromRGB(58, 64, 82),
        glassHighlight = Color3.fromRGB(255, 255, 255),
        glassShadow = Color3.fromRGB(0, 0, 0),

        default = Color3.fromRGB(68, 74, 92),
        defaultForeground = Color3.fromRGB(248, 250, 252),
        defaultSoft = Color3.fromRGB(42, 46, 58),
        defaultSoftForeground = Color3.fromRGB(220, 226, 238),

        accent = Color3.fromRGB(0, 118, 255),
        accentForeground = Color3.fromRGB(255, 255, 255),
        accentSoft = Color3.fromRGB(18, 52, 98),
        accentSoftForeground = Color3.fromRGB(120, 185, 255),

        success = Color3.fromRGB(23, 201, 100),
        successForeground = Color3.fromRGB(0, 0, 0),
        successSoft = Color3.fromRGB(15, 64, 38),
        successSoftForeground = Color3.fromRGB(82, 224, 145),

        warning = Color3.fromRGB(245, 165, 36),
        warningForeground = Color3.fromRGB(0, 0, 0),
        warningSoft = Color3.fromRGB(72, 48, 14),
        warningSoftForeground = Color3.fromRGB(252, 194, 94),

        danger = Color3.fromRGB(243, 18, 96),
        dangerForeground = Color3.fromRGB(255, 255, 255),
        dangerSoft = Color3.fromRGB(76, 16, 40),
        dangerSoftForeground = Color3.fromRGB(252, 122, 168),
    },
    light = {
        background = Color3.fromRGB(238, 242, 248),
        foreground = Color3.fromRGB(17, 24, 34),
        muted = Color3.fromRGB(98, 108, 124),
        surface = Color3.fromRGB(255, 255, 255),
        surfaceSecondary = Color3.fromRGB(232, 237, 245),
        overlay = Color3.fromRGB(255, 255, 255),
        border = Color3.fromRGB(200, 210, 226),
        divider = Color3.fromRGB(214, 222, 234),
        glassHighlight = Color3.fromRGB(255, 255, 255),
        glassShadow = Color3.fromRGB(120, 136, 160),

        default = Color3.fromRGB(212, 220, 232),
        defaultForeground = Color3.fromRGB(17, 24, 34),
        defaultSoft = Color3.fromRGB(238, 242, 248),
        defaultSoftForeground = Color3.fromRGB(52, 62, 78),

        accent = Color3.fromRGB(0, 111, 238),
        accentForeground = Color3.fromRGB(255, 255, 255),
        accentSoft = Color3.fromRGB(218, 234, 255),
        accentSoftForeground = Color3.fromRGB(0, 88, 192),

        success = Color3.fromRGB(23, 201, 100),
        successForeground = Color3.fromRGB(255, 255, 255),
        successSoft = Color3.fromRGB(216, 248, 228),
        successSoftForeground = Color3.fromRGB(12, 118, 56),

        warning = Color3.fromRGB(245, 165, 36),
        warningForeground = Color3.fromRGB(0, 0, 0),
        warningSoft = Color3.fromRGB(254, 240, 212),
        warningSoftForeground = Color3.fromRGB(142, 92, 16),

        danger = Color3.fromRGB(243, 18, 96),
        dangerForeground = Color3.fromRGB(255, 255, 255),
        dangerSoft = Color3.fromRGB(254, 220, 232),
        dangerSoftForeground = Color3.fromRGB(146, 11, 58),
    },
}

Flow.ActiveThemeName = "dark"
Flow.Theme = {}
for k, v in pairs(Flow.Themes.dark) do
    Flow.Theme[k] = v
end
Flow._themeListeners = {}

--// Unified Animation Presets (Identical across all 142 components)
Flow.Anim = {
    HoverTime = 0.20,
    PressTime = 0.12,
    ReleaseTime = 0.22,
    SpringTime = 0.30,
    SlideTime = 0.28,
    FadeTime = 0.22,
    HoverScale = 1.015,
    PressScale = 0.96,
    EasingSmooth = Enum.EasingStyle.Quint,
    EasingSpring = Enum.EasingStyle.Back,
}

Flow.Glass = {
    Enabled = true,
    WindowTransparency = 0.16,
    SurfaceTransparency = 0.26,
    ControlTransparency = 0.32,
    OverlayTransparency = 0.14,
    RimTransparency = 0.35,
    UseWorldBlur = true,
}

Flow.Radius = {
    none = 0,
    sm = 8,
    md = 12,
    lg = 16,
    xl = 22,
    full = 999,
}

Flow.Fonts = {
    sans = Enum.Font.GothamMedium,
    bold = Enum.Font.GothamBold,
    regular = Enum.Font.Gotham,
    mono = Enum.Font.RobotoMono,
}

--// Core Helpers
local function create(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                inst[k] = v
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            if child then
                child.Parent = inst
            end
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function tween(inst, props, duration, style, dir)
    if not inst or not inst.Parent then return nil end
    local info = TweenInfo.new(
        duration or Flow.Anim.HoverTime,
        style or Flow.Anim.EasingSmooth,
        dir or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

local function addCorner(inst, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or Flow.Radius.md),
        Parent = inst,
    })
end

local function addPadding(inst, top, right, bottom, left)
    local t = top or 8
    local r = right or t
    local b = bottom or t
    local l = left or r
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r),
        PaddingBottom = UDim.new(0, b),
        PaddingLeft = UDim.new(0, l),
        Parent = inst,
    })
end

local function addList(inst, direction, padding, hAlign, vAlign)
    return create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, padding or 8),
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = inst,
    })
end

--// ULTRA-REALISTIC LIQUID GLASS ENGINE
local function applyLiquidGlass(inst, opts)
    opts = opts or {}
    local baseTrans = opts.Transparency or Flow.Glass.SurfaceTransparency
    local tint = opts.Tint or Flow.Theme.surface
    local rimThickness = opts.RimThickness or 1.2
    local isDark = (Flow.ActiveThemeName == "dark")

    inst.BackgroundColor3 = tint
    inst.BackgroundTransparency = Flow.Glass.Enabled and baseTrans or 0

    -- 1) Specular Refraction Sheen Gradient (gives curved glass depth)
    local sheen = inst:FindFirstChild("_GlassSheen") or create("UIGradient", {
        Name = "_GlassSheen",
        Rotation = opts.Rotation or 132,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Flow.Theme.glassHighlight),
            ColorSequenceKeypoint.new(0.45, tint),
            ColorSequenceKeypoint.new(1, isDark and Flow.Theme.surfaceSecondary or tint),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, math.clamp(baseTrans - 0.10, 0.05, 0.9)),
            NumberSequenceKeypoint.new(0.5, baseTrans + 0.04),
            NumberSequenceKeypoint.new(1, baseTrans),
        }),
        Parent = inst,
    })

    -- 2) 3D Rim-Lit Glass Stroke (bright top-left specular edge -> soft bottom-right)
    local stroke = inst:FindFirstChild("_GlassRim") or create("UIStroke", {
        Name = "_GlassRim",
        Color = Color3.new(1, 1, 1),
        Thickness = rimThickness,
        Transparency = Flow.Glass.RimTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })

    local rimGrad = stroke:FindFirstChild("_RimGrad") or create("UIGradient", {
        Name = "_RimGrad",
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Flow.Theme.glassHighlight),
            ColorSequenceKeypoint.new(0.5, Flow.Theme.border),
            ColorSequenceKeypoint.new(1, isDark and Color3.fromRGB(40, 44, 58) or Flow.Theme.border),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.5, 0.55),
            NumberSequenceKeypoint.new(1, 0.35),
        }),
        Parent = stroke,
    })

    return sheen, stroke, rimGrad
end

--// UNIFIED LIQUID GLASS INTERACTION & ANIMATION (Identical across all components)
local function attachGlassInteraction(btn, opts)
    opts = opts or {}
    local baseTrans = opts.BaseTransparency or btn.BackgroundTransparency or Flow.Glass.ControlTransparency
    local hoverTrans = math.max(0.04, baseTrans - 0.14)
    local sc = btn:FindFirstChildOfClass("UIScale") or create("UIScale", { Scale = 1, Parent = btn })
    local rim = btn:FindFirstChild("_GlassRim")
    local sheen = btn:FindFirstChild("_GlassSheen")

    btn.MouseEnter:Connect(function()
        tween(sc, { Scale = opts.HoverScale or Flow.Anim.HoverScale }, Flow.Anim.HoverTime, Flow.Anim.EasingSmooth)
        tween(btn, { BackgroundTransparency = hoverTrans }, Flow.Anim.HoverTime)
        if rim then
            tween(rim, { Transparency = 0.12 }, Flow.Anim.HoverTime)
        end
        if sheen then
            tween(sheen, { Rotation = 148 }, Flow.Anim.HoverTime)
        end
    end)

    btn.MouseLeave:Connect(function()
        tween(sc, { Scale = 1 }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring)
        tween(btn, { BackgroundTransparency = baseTrans }, Flow.Anim.HoverTime)
        if rim then
            tween(rim, { Transparency = Flow.Glass.RimTransparency }, Flow.Anim.HoverTime)
        end
        if sheen then
            tween(sheen, { Rotation = 132 }, Flow.Anim.HoverTime)
        end
    end)

    btn.MouseButton1Down:Connect(function()
        tween(sc, { Scale = Flow.Anim.PressScale }, Flow.Anim.PressTime, Flow.Anim.EasingSmooth)
    end)

    btn.MouseButton1Up:Connect(function()
        tween(sc, { Scale = opts.HoverScale or Flow.Anim.HoverScale }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring)
        -- Specular click ripple flash
        if opts.Ripple ~= false and btn.ClipsDescendants then
            local rip = create("Frame", {
                Size = UDim2.fromOffset(10, 10),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.65,
                ZIndex = btn.ZIndex + 2,
                Parent = btn,
            })
            addCorner(rip, Flow.Radius.full)
            local maxD = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y, 60) * 1.4
            tween(rip, { Size = UDim2.fromOffset(maxD, maxD), BackgroundTransparency = 1 }, 0.36, Enum.EasingStyle.Quad)
            task.delay(0.38, function()
                if rip and rip.Parent then rip:Destroy() end
            end)
        end
    end)
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function getColorPair(colorName, variant)
    local t = Flow.Theme
    local key = colorName or "default"
    local base = t[key] or t.default
    local fg = t[key .. "Foreground"] or t.defaultForeground
    local soft = t[key .. "Soft"] or t.defaultSoft
    local softFg = t[key .. "SoftForeground"] or t.defaultSoftForeground

    if variant == "soft" or variant == "flat" then
        return soft, softFg, base
    elseif variant == "outline" or variant == "bordered" then
        return t.surface, base, base
    elseif variant == "ghost" or variant == "light" then
        return t.surface, softFg, base
    else
        return base, fg, base
    end
end

local function onThemeChange(fn)
    table.insert(Flow._themeListeners, fn)
end

function Flow:SetTheme(themeName, customTokens)
    local base = self.Themes[themeName] or self.Themes.dark
    self.ActiveThemeName = themeName
    for k, v in pairs(base) do
        self.Theme[k] = v
    end
    if customTokens then
        for k, v in pairs(customTokens) do
            self.Theme[k] = v
        end
    end
    for _, fn in ipairs(self._themeListeners) do
        pcall(fn, self.Theme)
    end
end

function Flow:SetGlass(enabled, transparency)
    self.Glass.Enabled = (enabled ~= false)
    if transparency then
        self.Glass.SurfaceTransparency = transparency
    end
end

--// Shared ScreenGui, Overlay Root & Optional World Blur
function Flow:_ensureRoot()
    if self._screenGui and self._screenGui.Parent then
        return self._screenGui
    end
    local gui = create("ScreenGui", {
        Name = "FlowUI_LiquidGlass",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = getGuiParent(),
    })
    self._screenGui = gui

    self._overlayLayer = create("Frame", {
        Name = "OverlayLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = gui,
    })

    self._toastLayer = create("Frame", {
        Name = "ToastLayer",
        Size = UDim2.new(0, 350, 1, -32),
        Position = UDim2.new(1, -366, 0, 16),
        BackgroundTransparency = 1,
        ZIndex = 300,
        Parent = gui,
    })
    addList(self._toastLayer, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

    self._tooltipBox = create("Frame", {
        Name = "Tooltip",
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        ZIndex = 400,
        Parent = gui,
    })
    addCorner(self._tooltipBox, self.Radius.sm)
    applyLiquidGlass(self._tooltipBox, { Tint = self.Theme.overlay, Transparency = 0.12 })
    addPadding(self._tooltipBox, 6, 10, 6, 10)
    self._tooltipLabel = create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = self.Fonts.sans,
        TextSize = 12,
        TextColor3 = self.Theme.foreground,
        Text = "",
        ZIndex = 401,
        Parent = self._tooltipBox,
    })

    return gui
end

function Flow:_setWorldBlur(active)
    if not self.Glass.UseWorldBlur then return end
    if active then
        if not self._blurEffect or not self._blurEffect.Parent then
            self._blurEffect = create("BlurEffect", { Name = "FlowUI_Blur", Size = 0, Parent = Lighting })
        end
        tween(self._blurEffect, { Size = 10 }, self.Anim.FadeTime)
    elseif self._blurEffect then
        local b = self._blurEffect
        tween(b, { Size = 0 }, self.Anim.FadeTime)
        task.delay(self.Anim.FadeTime + 0.02, function()
            if b and b.Size == 0 then b:Destroy() end
        end)
    end
end

function Flow:Destroy()
    self:_setWorldBlur(false)
    if self._screenGui then
        self._screenGui:Destroy()
        self._screenGui = nil
    end
end

function Flow:_attachTooltip(target, text)
    self:_ensureRoot()
    local hovering = false
    target.MouseEnter:Connect(function()
        hovering = true
        self._tooltipLabel.Text = tostring(text)
        self._tooltipLabel.TextColor3 = self.Theme.foreground
        local pos = UserInputService:GetMouseLocation()
        self._tooltipBox.Position = UDim2.fromOffset(pos.X + 12, pos.Y + 12)
        self._tooltipBox.Visible = true
    end)
    target.MouseMoved:Connect(function(x, y)
        if hovering then
            self._tooltipBox.Position = UDim2.fromOffset(x + 14, y + 14)
        end
    end)
    target.MouseLeave:Connect(function()
        hovering = false
        self._tooltipBox.Visible = false
    end)
end

--// Container Wrapper
local ContainerMethods = {}
ContainerMethods.__index = ContainerMethods

local function wrapContainer(frame)
    return setmetatable({
        Instance = frame,
        _frame = frame,
    }, ContainerMethods)
end

--// Liquid Glass Window / App Shell
function Flow:CreateWindow(opts)
    opts = opts or {}
    self:_ensureRoot()

    local title = opts.Title or "FlowUI"
    local subtitle = opts.Subtitle or "HeroUI Liquid Glass"
    local size = opts.Size or UDim2.fromOffset(840, 560)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightControl

    local winFrame = create("Frame", {
        Name = "FlowWindow",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        ClipsDescendants = true,
        Parent = self._screenGui,
    })
    addCorner(winFrame, self.Radius.xl)
    applyLiquidGlass(winFrame, { Tint = self.Theme.background, Transparency = self.Glass.WindowTransparency, RimThickness = 1.5 })

    local winScale = create("UIScale", { Scale = 0.94, Parent = winFrame })
    tween(winScale, { Scale = 1 }, self.Anim.SpringTime, self.Anim.EasingSpring)

    -- Header / Glass Navbar
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 54),
        BorderSizePixel = 0,
        Parent = winFrame,
    })
    applyLiquidGlass(header, { Tint = self.Theme.surface, Transparency = 0.25, RimThickness = 0 })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = self.Theme.glassHighlight,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = header,
    })
    makeDraggable(header, winFrame)

    local brandBox = create("Frame", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Parent = header,
    })
    addList(brandBox, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local logoBadge = create("Frame", {
        Size = UDim2.fromOffset(30, 30),
        Parent = brandBox,
    })
    addCorner(logoBadge, self.Radius.sm)
    applyLiquidGlass(logoBadge, { Tint = self.Theme.accent, Transparency = 0.12 })
    create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = self.Fonts.bold,
        TextSize = 14,
        TextColor3 = self.Theme.accentForeground,
        Text = string.sub(title, 1, 1):upper(),
        Parent = logoBadge,
    })

    local titleCol = create("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Parent = brandBox,
    })
    addList(titleCol, Enum.FillDirection.Vertical, 1)
    local titleLbl = create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = self.Fonts.bold,
        TextSize = 14,
        TextColor3 = self.Theme.foreground,
        Text = title,
        Parent = titleCol,
    })
    local subLbl = create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = self.Fonts.regular,
        TextSize = 11,
        TextColor3 = self.Theme.muted,
        Text = subtitle,
        Parent = titleCol,
    })

    local actionsBox = create("Frame", {
        Size = UDim2.new(0.4, -16, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = header,
    })
    addList(actionsBox, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    local themeBtn = create("TextButton", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 28),
        Font = self.Fonts.sans,
        TextSize = 11,
        TextColor3 = self.Theme.defaultSoftForeground,
        Text = "Theme: " .. self.ActiveThemeName,
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = actionsBox,
    })
    addCorner(themeBtn, self.Radius.sm)
    addPadding(themeBtn, 0, 10, 0, 10)
    applyLiquidGlass(themeBtn, { Tint = self.Theme.defaultSoft, Transparency = 0.28 })
    attachGlassInteraction(themeBtn, { BaseTransparency = 0.28 })
    themeBtn.MouseButton1Click:Connect(function()
        local nextTheme = (self.ActiveThemeName == "dark") and "light" or "dark"
        self:SetTheme(nextTheme)
        themeBtn.Text = "Theme: " .. nextTheme
    end)

    local closeBtn = create("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Font = self.Fonts.bold,
        TextSize = 13,
        TextColor3 = self.Theme.muted,
        Text = "×",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = actionsBox,
    })
    addCorner(closeBtn, self.Radius.sm)
    applyLiquidGlass(closeBtn, { Tint = self.Theme.defaultSoft, Transparency = 0.28 })
    attachGlassInteraction(closeBtn, { BaseTransparency = 0.28 })

    local isOpen = true
    local function setVisible(state)
        isOpen = state
        if isOpen then
            winFrame.Visible = true
            winScale.Scale = 0.94
            tween(winScale, { Scale = 1 }, self.Anim.SpringTime, self.Anim.EasingSpring)
        else
            tween(winScale, { Scale = 0.94 }, self.Anim.PressTime, self.Anim.EasingSmooth)
            task.delay(self.Anim.PressTime, function()
                if not isOpen then winFrame.Visible = false end
            end)
        end
    end

    closeBtn.MouseButton1Click:Connect(function() setVisible(not isOpen) end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == toggleKey then
            setVisible(not isOpen)
        end
    end)

    -- Body: Glass Sidebar + Content Area
    local body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -54),
        Position = UDim2.fromOffset(0, 54),
        BackgroundTransparency = 1,
        Parent = winFrame,
    })

    local sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 194, 1, 0),
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = body,
    })
    applyLiquidGlass(sidebar, { Tint = self.Theme.surface, Transparency = 0.30, RimThickness = 0 })
    addPadding(sidebar, 12, 10, 12, 10)
    addList(sidebar, Enum.FillDirection.Vertical, 5)

    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.fromOffset(194, 0),
        BackgroundColor3 = self.Theme.glassHighlight,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Parent = body,
    })

    local contentHolder = create("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -195, 1, 0),
        Position = UDim2.fromOffset(195, 0),
        BackgroundTransparency = 1,
        Parent = body,
    })

    onThemeChange(function(t)
        applyLiquidGlass(winFrame, { Tint = t.background, Transparency = self.Glass.WindowTransparency, RimThickness = 1.5 })
        applyLiquidGlass(header, { Tint = t.surface, Transparency = 0.25, RimThickness = 0 })
        applyLiquidGlass(sidebar, { Tint = t.surface, Transparency = 0.30, RimThickness = 0 })
        titleLbl.TextColor3 = t.foreground
        subLbl.TextColor3 = t.muted
        themeBtn.TextColor3 = t.defaultSoftForeground
    end)

    local Window = {
        Frame = winFrame,
        Tabs = {},
        _activeTab = nil,
    }

    function Window:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Title or "Tab"
        local tabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Flow.Theme.accentSoft,
            BackgroundTransparency = 1,
            Font = Flow.Fonts.sans,
            TextSize = 13,
            TextColor3 = Flow.Theme.muted,
            Text = "  " .. tabName,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ClipsDescendants = true,
            Parent = sidebar,
        })
        addCorner(tabBtn, Flow.Radius.md)
        local tabScale = create("UIScale", { Scale = 1, Parent = tabBtn })

        local page = create("ScrollingFrame", {
            Name = "Page_" .. tabName,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Flow.Theme.border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = contentHolder,
        })
        addPadding(page, 16, 18, 24, 18)
        addList(page, Enum.FillDirection.Vertical, 12)

        local tabObj = wrapContainer(page)
        tabObj.Button = tabBtn
        tabObj.Page = page

        function tabObj:Select()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Button, { BackgroundTransparency = 1, TextColor3 = Flow.Theme.muted }, Flow.Anim.HoverTime)
            end
            page.Visible = true
            tween(tabBtn, {
                BackgroundTransparency = 0.25,
                BackgroundColor3 = Flow.Theme.accentSoft,
                TextColor3 = Flow.Theme.accentSoftForeground,
            }, Flow.Anim.HoverTime)
            Window._activeTab = tabObj
        end

        tabBtn.MouseEnter:Connect(function()
            tween(tabScale, { Scale = Flow.Anim.HoverScale }, Flow.Anim.HoverTime)
        end)
        tabBtn.MouseLeave:Connect(function()
            tween(tabScale, { Scale = 1 }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring)
        end)
        tabBtn.MouseButton1Down:Connect(function()
            tween(tabScale, { Scale = Flow.Anim.PressScale }, Flow.Anim.PressTime)
        end)
        tabBtn.MouseButton1Up:Connect(function()
            tween(tabScale, { Scale = 1 }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring)
        end)
        tabBtn.MouseButton1Click:Connect(function()
            tabObj:Select()
        end)

        table.insert(Window.Tabs, tabObj)
        if #Window.Tabs == 1 then
            tabObj:Select()
        end
        return tabObj
    end

    function Window:SelectTab(indexOrName)
        for i, t in ipairs(self.Tabs) do
            if i == indexOrName or t.Page.Name == "Page_" .. tostring(indexOrName) then
                t:Select()
                return t
            end
        end
    end

    function Window:Toggle(state)
        if state == nil then setVisible(not isOpen) else setVisible(state) end
    end

    return Window
end

--============================================================================--
-- SECTION 1: LIQUID GLASS LAYOUT, TYPOGRAPHY & CARDS
--============================================================================--

function ContainerMethods:Typography(opts)
    opts = opts or {}
    local variant = opts.Variant or "body"
    local sizes = { h1 = 24, h2 = 20, h3 = 17, h4 = 15, body = 13, small = 12, caption = 11 }
    local font = (variant == "h1" or variant == "h2" or variant == "h3") and Flow.Fonts.bold or Flow.Fonts.regular
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = opts.Mono and Flow.Fonts.mono or font,
        TextSize = opts.Size or sizes[variant] or 13,
        TextColor3 = opts.Color and (Flow.Theme[opts.Color] or opts.Color) or (variant == "caption" and Flow.Theme.muted or Flow.Theme.foreground),
        Text = opts.Text or "Typography",
        TextWrapped = true,
        TextXAlignment = opts.Align or Enum.TextXAlignment.Left,
        Parent = self._frame,
    })
    return { Instance = lbl, SetText = function(_, t) lbl.Text = tostring(t) end }
end

function ContainerMethods:Label(opts)
    opts = opts or {}
    return self:Typography({ Text = opts.Text or "Label", Variant = "h4", Size = opts.Size or 13, Color = opts.Color or "foreground" })
end

function ContainerMethods:Description(opts)
    opts = opts or {}
    return self:Typography({ Text = opts.Text or "Helper description text.", Variant = "caption", Size = opts.Size or 12, Color = "muted" })
end

function ContainerMethods:ErrorMessage(opts)
    opts = opts or {}
    return self:Typography({ Text = opts.Text or "Invalid input value.", Variant = "caption", Size = 12, Color = "dangerSoftForeground" })
end

function ContainerMethods:FieldError(opts) return self:ErrorMessage(opts) end

function ContainerMethods:Separator(opts)
    opts = opts or {}
    local vertical = opts.Orientation == "vertical"
    local line = create("Frame", {
        Size = vertical and UDim2.new(0, 1, 0, opts.Length or 24) or UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Flow.Theme.glassHighlight,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = self._frame,
    })
    return { Instance = line }
end

function ContainerMethods:Surface(opts)
    opts = opts or {}
    local card = create("Frame", {
        Size = opts.Size or UDim2.new(1, 0, 0, 0),
        AutomaticSize = opts.Size and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        Parent = self._frame,
    })
    addCorner(card, Flow.Radius[opts.Radius or "lg"] or Flow.Radius.lg)
    applyLiquidGlass(card, {
        Tint = Flow.Theme[opts.Background or "surface"] or Flow.Theme.surface,
        Transparency = opts.Transparency or Flow.Glass.SurfaceTransparency,
        RimThickness = (opts.Border == false) and 0 or 1.1,
    })
    addPadding(card, opts.Padding or 14)
    addList(card, opts.Direction or Enum.FillDirection.Vertical, opts.Gap or 8)
    return wrapContainer(card)
end

function ContainerMethods:Card(opts)
    opts = opts or {}
    local box = self:Surface({ Radius = opts.Radius or "lg", Padding = 14, Gap = 8 })
    if opts.Title or opts.Description then
        local hdr = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = box._frame,
        })
        addList(hdr, Enum.FillDirection.Vertical, 2)
        if opts.Title then
            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = Flow.Fonts.bold,
                TextSize = 15,
                TextColor3 = Flow.Theme.foreground,
                Text = opts.Title,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = hdr,
            })
        end
        if opts.Description then
            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = Flow.Fonts.regular,
                TextSize = 12,
                TextColor3 = Flow.Theme.muted,
                Text = opts.Description,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = hdr,
            })
        end
    end
    return box
end

function ContainerMethods:ItemCard(opts)
    opts = opts or {}
    local btn = create("TextButton", {
        Size = opts.Size or UDim2.new(1, 0, 0, 60),
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.lg)
    applyLiquidGlass(btn, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
    attachGlassInteraction(btn, { BaseTransparency = Flow.Glass.SurfaceTransparency })
    addPadding(btn, 10, 14, 10, 14)

    local row = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = btn })
    addList(row, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local iconBox = create("Frame", { Size = UDim2.fromOffset(36, 36), Parent = row })
    addCorner(iconBox, Flow.Radius.md)
    applyLiquidGlass(iconBox, { Tint = Flow.Theme.accentSoft, Transparency = 0.2 })
    create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 14,
        TextColor3 = Flow.Theme.accentSoftForeground,
        Text = opts.Icon or "★",
        Parent = iconBox,
    })

    local txtCol = create("Frame", { Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1, Parent = row })
    addList(txtCol, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Title or "Item Card",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = txtCol,
    })
    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 11,
        TextColor3 = Flow.Theme.muted,
        Text = opts.Subtitle or "Description",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = txtCol,
    })

    if opts.Callback then btn.MouseButton1Click:Connect(opts.Callback) end
    return { Instance = btn }
end

function ContainerMethods:ItemCardGroup(opts)
    opts = opts or {}
    local grid = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    create("UIGridLayout", {
        CellSize = opts.CellSize or UDim2.new(0.48, 0, 0, 64),
        CellPadding = UDim2.fromOffset(10, 10),
        Parent = grid,
    })
    local wrapper = wrapContainer(grid)
    if opts.Items then
        for _, item in ipairs(opts.Items) do wrapper:ItemCard(item) end
    end
    return wrapper
end

function ContainerMethods:HoloCard(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "HoloCard", Description = opts.Description or "Interactive liquid glass refraction" })
    local sheen = card._frame:FindFirstChild("_GlassSheen")
    if sheen then
        sheen.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Flow.Theme.accentSoft),
            ColorSequenceKeypoint.new(0.5, Flow.Theme.glassHighlight),
            ColorSequenceKeypoint.new(1, Flow.Theme.dangerSoft),
        })
        card._frame.MouseMoved:Connect(function(x, y)
            tween(sheen, { Rotation = (x + y) % 360 }, 0.12)
        end)
    end
    return card
end

function ContainerMethods:EmptyState(opts)
    opts = opts or {}
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, opts.Height or 140), Parent = self._frame })
    addCorner(box, Flow.Radius.lg)
    applyLiquidGlass(box, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
    addList(box, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = 22, TextColor3 = Flow.Theme.muted, Text = opts.Icon or "∅", Parent = box })
    create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = 14, TextColor3 = Flow.Theme.foreground, Text = opts.Title or "No data available", Parent = box })
    create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 12, TextColor3 = Flow.Theme.muted, Text = opts.Description or "Items will appear here once created.", Parent = box })
    return wrapContainer(box)
end

function ContainerMethods:Skeleton(opts)
    opts = opts or {}
    local sk = create("Frame", { Size = opts.Size or UDim2.new(1, 0, 0, opts.Height or 20), Parent = self._frame })
    addCorner(sk, Flow.Radius[opts.Radius or "md"] or Flow.Radius.md)
    applyLiquidGlass(sk, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.35 })
    task.spawn(function()
        while sk and sk.Parent do
            tween(sk, { BackgroundTransparency = 0.65 }, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.75)
            if not (sk and sk.Parent) then break end
            tween(sk, { BackgroundTransparency = 0.25 }, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.75)
        end
    end)
    return { Instance = sk }
end

function ContainerMethods:TextShimmer(opts)
    opts = opts or {}
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.sans,
        TextSize = opts.Size or 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Text or "Thinking...",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._frame,
    })
    task.spawn(function()
        while lbl and lbl.Parent do
            tween(lbl, { TextTransparency = 0.6 }, 0.6)
            task.wait(0.65)
            if not (lbl and lbl.Parent) then break end
            tween(lbl, { TextTransparency = 0 }, 0.6)
            task.wait(0.65)
        end
    end)
    return { Instance = lbl }
end

function ContainerMethods:Spinner(opts)
    opts = opts or {}
    local sz = opts.Size or 22
    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, sz + 6), BackgroundTransparency = 1, Parent = self._frame })
    addList(holder, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local ring = create("Frame", { Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1, Parent = holder })
    addCorner(ring, Flow.Radius.full)
    local stroke = create("UIStroke", { Color = Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent, Thickness = 2.5, Parent = ring })
    local grad = create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.85),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = stroke,
    })
    local conn = RunService.RenderStepped:Connect(function(dt)
        if ring.Parent then grad.Rotation = (grad.Rotation + dt * 360) % 360 end
    end)
    ring.Destroying:Connect(function() conn:Disconnect() end)
    if opts.Label then
        create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 12, TextColor3 = Flow.Theme.muted, Text = opts.Label, Parent = holder })
    end
    return { Instance = holder }
end
function ContainerMethods:Loader(opts) return self:Spinner(opts) end

function ContainerMethods:Kbd(opts)
    opts = opts or {}
    local kbd = create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 22),
        Font = Flow.Fonts.mono,
        TextSize = 11,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Text or "Ctrl + K",
        Parent = self._frame,
    })
    addCorner(kbd, Flow.Radius.sm)
    applyLiquidGlass(kbd, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.25 })
    addPadding(kbd, 2, 8, 2, 8)
    return { Instance = kbd }
end

function ContainerMethods:Chip(opts)
    opts = opts or {}
    local bg, fg = getColorPair(opts.Color or "default", opts.Variant or "soft")
    local chip = create("TextButton", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 24),
        Font = Flow.Fonts.sans,
        TextSize = 11,
        TextColor3 = fg,
        Text = opts.Text or "Chip",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = self._frame,
    })
    addCorner(chip, Flow.Radius.full)
    addPadding(chip, 0, 10, 0, 10)
    local trans = (opts.Variant == "solid") and 0.14 or 0.26
    applyLiquidGlass(chip, { Tint = bg, Transparency = trans })
    attachGlassInteraction(chip, { BaseTransparency = trans })
    if opts.OnClose then
        chip.Text = chip.Text .. "  ×"
        chip.MouseButton1Click:Connect(function()
            opts.OnClose()
            chip:Destroy()
        end)
    end
    return { Instance = chip, SetText = function(_, t) chip.Text = tostring(t) end }
end

function ContainerMethods:Badge(opts)
    opts = opts or {}
    return self:Chip({ Text = opts.Text or "New", Color = opts.Color or "accent", Variant = opts.Variant or "solid" })
end

function ContainerMethods:TrendChip(opts)
    opts = opts or {}
    local up = (opts.Direction or "up") == "up"
    return self:Chip({ Text = (up and "▲ " or "▼ ") .. tostring(opts.Value or "+12.5%"), Color = up and "success" or "danger", Variant = "soft" })
end

function ContainerMethods:Avatar(opts)
    opts = opts or {}
    local sz = opts.Size or 36
    local bg, fg = getColorPair(opts.Color or "accent", "soft")
    local av = create("Frame", { Size = UDim2.fromOffset(sz, sz), Parent = self._frame })
    addCorner(av, Flow.Radius.full)
    applyLiquidGlass(av, { Tint = bg, Transparency = 0.2 })
    if opts.Image then
        local img = create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = opts.Image, Parent = av })
        addCorner(img, Flow.Radius.full)
    else
        create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = math.floor(sz * 0.4), TextColor3 = fg, Text = opts.Initials or "FL", Parent = av })
    end
    return { Instance = av }
end

function ContainerMethods:AvatarGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, -8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local w = wrapContainer(row)
    for _, item in ipairs(opts.Items or { { Initials = "A" }, { Initials = "B" }, { Initials = "C" } }) do w:Avatar(item) end
    return w
end

function ContainerMethods:Link(opts)
    opts = opts or {}
    local btn = create("TextButton", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.sans,
        TextSize = opts.Size or 13,
        TextColor3 = Flow.Theme.accentSoftForeground,
        Text = opts.Text or "External Link ↗",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    local sc = create("UIScale", { Scale = 1, Parent = btn })
    btn.MouseEnter:Connect(function() tween(sc, { Scale = 1.02 }, Flow.Anim.HoverTime) end)
    btn.MouseLeave:Connect(function() tween(sc, { Scale = 1 }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring) end)
    btn.MouseButton1Click:Connect(function()
        if opts.Url and type(setclipboard) == "function" then pcall(setclipboard, opts.Url) end
        if opts.Callback then opts.Callback() end
    end)
    return { Instance = btn }
end

function ContainerMethods:CloseButton(opts)
    opts = opts or {}
    local btn = create("TextButton", {
        Size = UDim2.fromOffset(26, 26),
        Font = Flow.Fonts.bold,
        TextSize = 12,
        TextColor3 = Flow.Theme.muted,
        Text = "×",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.full)
    applyLiquidGlass(btn, { Tint = Flow.Theme.defaultSoft, Transparency = 0.28 })
    attachGlassInteraction(btn, { BaseTransparency = 0.28 })
    if opts.Callback then btn.MouseButton1Click:Connect(opts.Callback) end
    return { Instance = btn }
end

function ContainerMethods:PressableFeedback(opts)
    opts = opts or {}
    local btn = create("TextButton", {
        Size = opts.Size or UDim2.new(1, 0, 0, 40),
        Font = Flow.Fonts.sans,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Text or "Press Me (Liquid Glass Feedback)",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.md)
    applyLiquidGlass(btn, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.ControlTransparency })
    attachGlassInteraction(btn, { BaseTransparency = Flow.Glass.ControlTransparency })
    if opts.Callback then btn.MouseButton1Click:Connect(opts.Callback) end
    return { Instance = btn }
end

function ContainerMethods:ScrollShadow(opts)
    opts = opts or {}
    local sc = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, opts.Height or 110),
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self._frame,
    })
    addCorner(sc, Flow.Radius.md)
    applyLiquidGlass(sc, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
    addPadding(sc, 10)
    addList(sc, Enum.FillDirection.Vertical, 6)
    return wrapContainer(sc)
end

function ContainerMethods:Resizable(opts)
    opts = opts or {}
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, opts.Height or 100), Parent = self._frame })
    addCorner(box, Flow.Radius.md)
    applyLiquidGlass(box, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
    local left = create("Frame", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundTransparency = 1, Parent = box })
    local right = create("Frame", { Size = UDim2.new(0.5, -3, 1, 0), Position = UDim2.new(0.5, 3, 0, 0), BackgroundTransparency = 1, Parent = box })
    local handle = create("TextButton", {
        Size = UDim2.new(0, 6, 1, 0),
        Position = UDim2.new(0.5, -3, 0, 0),
        BackgroundColor3 = Flow.Theme.accent,
        BackgroundTransparency = 0.25,
        Text = "",
        AutoButtonColor = false,
        Parent = box,
    })
    addCorner(handle, Flow.Radius.full)
    local dragging = false
    handle.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - box.AbsolutePosition.X) / math.max(1, box.AbsoluteSize.X), 0.2, 0.8)
            left.Size = UDim2.new(rel, -3, 1, 0)
            right.Size = UDim2.new(1 - rel, -3, 1, 0)
            right.Position = UDim2.new(rel, 3, 0, 0)
            handle.Position = UDim2.new(rel, -3, 0, 0)
        end
    end)
    return { Left = wrapContainer(left), Right = wrapContainer(right), Instance = box }
end

function ContainerMethods:Navbar(opts)
    opts = opts or {}
    local bar = create("Frame", { Size = UDim2.new(1, 0, 0, 44), Parent = self._frame })
    addCorner(bar, Flow.Radius.md)
    applyLiquidGlass(bar, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
    addPadding(bar, 0, 12, 0, 12)
    addList(bar, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    create("TextLabel", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = 13, TextColor3 = Flow.Theme.foreground, Text = opts.Brand or "HeroUI", Parent = bar })
    local w = wrapContainer(bar)
    for _, item in ipairs(opts.Items or { "Home", "Docs", "Settings" }) do w:Chip({ Text = item, Variant = "ghost" }) end
    return w
end

function ContainerMethods:Sidebar(opts)
    opts = opts or {}
    local box = self:Surface({ Padding = 10, Gap = 4 })
    for _, item in ipairs(opts.Items or { "Dashboard", "Analytics", "Users" }) do
        local b = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            Font = Flow.Fonts.sans,
            TextSize = 12,
            TextColor3 = Flow.Theme.foreground,
            Text = "  " .. item,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ClipsDescendants = true,
            Parent = box._frame,
        })
        addCorner(b, Flow.Radius.sm)
        applyLiquidGlass(b, { Tint = Flow.Theme.defaultSoft, Transparency = 0.55, RimThickness = 0 })
        attachGlassInteraction(b, { BaseTransparency = 0.55 })
        b.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback(item) end end)
    end
    return box
end

function ContainerMethods:AppLayout(opts)
    opts = opts or {}
    local box = self:Surface({ Padding = 8, Gap = 8 })
    box:Navbar({ Brand = opts.Brand or "AppLayout" })
    return box
end

function ContainerMethods:Toolbar(opts)
    opts = opts or {}
    local bar = create("Frame", { Size = UDim2.new(1, 0, 0, 40), Parent = self._frame })
    addCorner(bar, Flow.Radius.md)
    applyLiquidGlass(bar, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
    addPadding(bar, 4, 8, 4, 8)
    addList(bar, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local w = wrapContainer(bar)
    for _, act in ipairs(opts.Actions or { "Bold", "Italic", "Code" }) do
        w:Button({ Text = act, Variant = "ghost", Size = UDim2.fromOffset(64, 28), Callback = function()
            if opts.Callback then opts.Callback(act) end
        end })
    end
    return w
end
function ContainerMethods:ActionBar(opts) return self:Toolbar(opts) end

function ContainerMethods:FloatingToc(opts)
    opts = opts or {}
    local box = self:Card({ Title = opts.Title or "On this page" })
    for _, item in ipairs(opts.Items or { "Overview", "Installation", "Usage", "API" }) do
        box:Link({ Text = "• " .. item, Callback = function() if opts.Callback then opts.Callback(item) end end })
    end
    return box
end

function ContainerMethods:Widget(opts)
    opts = opts or {}
    return self:Card({ Title = opts.Title or "Widget", Description = opts.Description or "Composable liquid glass widget" })
end

--============================================================================--
-- SECTION 2: BUTTONS, TOGGLES & FORMS / INPUTS
--============================================================================--

function ContainerMethods:Button(opts)
    opts = opts or {}
    local bg = getColorPair(opts.Color or "accent", opts.Variant or "solid")
    local _, fg = getColorPair(opts.Color or "accent", opts.Variant or "solid")
    local trans = (opts.Variant == "ghost") and 0.72 or ((opts.Variant == "solid" or not opts.Variant) and 0.14 or 0.30)
    local btn = create("TextButton", {
        Size = opts.Size or UDim2.new(0, 148, 0, 36),
        Font = Flow.Fonts.sans,
        TextSize = 13,
        TextColor3 = fg,
        Text = opts.IsPending and "Loading..." or (opts.Text or "Button"),
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius[opts.Radius or "md"] or Flow.Radius.md)
    applyLiquidGlass(btn, { Tint = bg, Transparency = trans })
    attachGlassInteraction(btn, { BaseTransparency = trans })
    if opts.Tooltip then Flow:_attachTooltip(btn, opts.Tooltip) end
    btn.MouseButton1Click:Connect(function()
        if not opts.IsDisabled and opts.Callback then opts.Callback() end
    end)
    return { Instance = btn, SetText = function(_, t) btn.Text = tostring(t) end }
end

function ContainerMethods:ButtonGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local w = wrapContainer(row)
    for _, item in ipairs(opts.Buttons or { { Text = "One" }, { Text = "Two" }, { Text = "Three" } }) do
        w:Button({
            Text = item.Text or item,
            Color = item.Color or opts.Color or "default",
            Variant = item.Variant or opts.Variant or "soft",
            Size = item.Size or UDim2.fromOffset(90, 34),
            Callback = item.Callback,
        })
    end
    return w
end

function ContainerMethods:ToggleButton(opts)
    opts = opts or {}
    local selected = opts.Default or false
    local btn = create("TextButton", {
        Size = opts.Size or UDim2.fromOffset(120, 34),
        Font = Flow.Fonts.sans,
        TextSize = 12,
        TextColor3 = selected and Flow.Theme.accentForeground or Flow.Theme.defaultSoftForeground,
        Text = opts.Text or "Toggle",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.md)
    applyLiquidGlass(btn, { Tint = selected and Flow.Theme.accent or Flow.Theme.defaultSoft, Transparency = 0.22 })
    attachGlassInteraction(btn, { BaseTransparency = 0.22 })
    local function render()
        tween(btn, {
            BackgroundColor3 = selected and Flow.Theme.accent or Flow.Theme.defaultSoft,
            TextColor3 = selected and Flow.Theme.accentForeground or Flow.Theme.defaultSoftForeground,
        }, Flow.Anim.HoverTime)
    end
    btn.MouseButton1Click:Connect(function()
        selected = not selected
        render()
        if opts.Callback then opts.Callback(selected) end
    end)
    return { Instance = btn, Get = function() return selected end, Set = function(_, v) selected = v; render() end }
end

function ContainerMethods:ToggleButtonGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6)
    local w = wrapContainer(row)
    for _, label in ipairs(opts.Items or { "Left", "Center", "Right" }) do
        w:ToggleButton({ Text = label, Size = UDim2.fromOffset(80, 32), Callback = function(v)
            if opts.Callback then opts.Callback(label, v) end
        end })
    end
    return w
end

function ContainerMethods:Checkbox(opts)
    opts = opts or {}
    local checked = opts.Default or false
    local row = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addList(row, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local box = create("Frame", { Size = UDim2.fromOffset(18, 18), Parent = row })
    addCorner(box, 5)
    applyLiquidGlass(box, { Tint = checked and Flow.Theme.accent or Flow.Theme.surfaceSecondary, Transparency = 0.18 })
    local boxScale = create("UIScale", { Scale = 1, Parent = box })
    local mark = create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 12,
        TextColor3 = Flow.Theme.accentForeground,
        Text = checked and "✓" or "",
        Parent = box,
    })
    create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 13, TextColor3 = Flow.Theme.foreground, Text = opts.Label or "Checkbox", Parent = row })
    local function render()
        boxScale.Scale = 0.85
        tween(boxScale, { Scale = 1 }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring)
        tween(box, { BackgroundColor3 = checked and Flow.Theme.accent or Flow.Theme.surfaceSecondary }, Flow.Anim.HoverTime)
        mark.Text = checked and "✓" or ""
    end
    row.MouseButton1Click:Connect(function()
        checked = not checked
        render()
        if opts.Callback then opts.Callback(checked) end
    end)
    return { Instance = row, Get = function() return checked end, Set = function(_, v) checked = v; render() end }
end

function ContainerMethods:CheckboxGroup(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Label or "Checkbox Group" })
    local state = {}
    for _, item in ipairs(opts.Items or { "Option A", "Option B", "Option C" }) do
        state[item] = false
        card:Checkbox({ Label = item, Callback = function(v) state[item] = v; if opts.Callback then opts.Callback(state) end end })
    end
    return card
end
function ContainerMethods:CheckboxButtonGroup(opts) return self:ToggleButtonGroup(opts) end

function ContainerMethods:RadioGroup(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Label or "Radio Group" })
    local selected = opts.Default or (opts.Items and opts.Items[1]) or "Option 1"
    local dots = {}
    for _, item in ipairs(opts.Items or { "Option 1", "Option 2", "Option 3" }) do
        local row = create("TextButton", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = card._frame })
        addList(row, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
        local outer = create("Frame", { Size = UDim2.fromOffset(18, 18), Parent = row })
        addCorner(outer, Flow.Radius.full)
        applyLiquidGlass(outer, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.2 })
        local inner = create("Frame", {
            Size = UDim2.fromOffset(8, 8),
            Position = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Flow.Theme.accent,
            Visible = (item == selected),
            Parent = outer,
        })
        addCorner(inner, Flow.Radius.full)
        create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 13, TextColor3 = Flow.Theme.foreground, Text = item, Parent = row })
        dots[item] = inner
        row.MouseButton1Click:Connect(function()
            selected = item
            for k, d in pairs(dots) do d.Visible = (k == selected) end
            if opts.Callback then opts.Callback(selected) end
        end)
    end
    return { Card = card, Get = function() return selected end }
end
function ContainerMethods:RadioButtonGroup(opts) return self:Segment(opts) end

function ContainerMethods:Switch(opts)
    opts = opts or {}
    local on = opts.Default or false
    local row = create("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = self._frame })
    local lbl = create("TextLabel", { Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 13, TextColor3 = Flow.Theme.foreground, Text = opts.Label or "Switch", TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    local track = create("Frame", { Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -44, 0.5, -12), Parent = row })
    addCorner(track, Flow.Radius.full)
    applyLiquidGlass(track, { Tint = on and Flow.Theme.accent or Flow.Theme.default, Transparency = 0.16 })
    local thumb = create("Frame", { Size = UDim2.fromOffset(18, 18), Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
    addCorner(thumb, Flow.Radius.full)
    local function render()
        tween(track, { BackgroundColor3 = on and Flow.Theme.accent or Flow.Theme.default }, Flow.Anim.HoverTime)
        tween(thumb, { Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring)
    end
    row.MouseButton1Click:Connect(function() on = not on; render(); if opts.Callback then opts.Callback(on) end end)
    return { Instance = row, Label = lbl, Get = function() return on end, Set = function(_, v) on = v; render() end }
end

function ContainerMethods:Slider(opts)
    opts = opts or {}
    local minV = opts.Min or 0
    local maxV = opts.Max or 100
    local val = math.clamp(opts.Default or minV, minV, maxV)

    local box = create("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = self._frame })
    local top = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = box })
    create("TextLabel", { Size = UDim2.new(0.7, 0, 1, 0), BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 12, TextColor3 = Flow.Theme.foreground, Text = opts.Label or "Slider", TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
    local valLbl = create("TextLabel", { Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.7, 0, 0, 0), BackgroundTransparency = 1, Font = Flow.Fonts.mono, TextSize = 12, TextColor3 = Flow.Theme.muted, Text = tostring(val), TextXAlignment = Enum.TextXAlignment.Right, Parent = top })
    local track = create("TextButton", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 26), Text = "", AutoButtonColor = false, Parent = box })
    addCorner(track, Flow.Radius.full)
    applyLiquidGlass(track, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.25 })
    local pct = (val - minV) / math.max(1e-5, maxV - minV)
    local fill = create("Frame", { Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = Flow.Theme.accent, Parent = track })
    addCorner(fill, Flow.Radius.full)
    local knob = create("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(pct, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
    addCorner(knob, Flow.Radius.full)
    local knobScale = create("UIScale", { Scale = 1, Parent = knob })

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        val = math.floor(minV + (maxV - minV) * rel + 0.5)
        local r = (val - minV) / math.max(1e-5, maxV - minV)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        if opts.Callback then opts.Callback(val) end
    end
    track.MouseButton1Down:Connect(function(x)
        dragging = true
        tween(knobScale, { Scale = 1.2 }, Flow.Anim.PressTime)
        updateFromX(x)
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            tween(knobScale, { Scale = 1 }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateFromX(i.Position.X) end
    end)
    return { Instance = box, Get = function() return val end }
end

function ContainerMethods:Rating(opts)
    opts = opts or {}
    local maxStars = opts.Max or 5
    local val = opts.Default or 3
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 4)
    local btns = {}
    local function render()
        for i, b in ipairs(btns) do b.TextColor3 = (i <= val) and Flow.Theme.warning or Flow.Theme.muted end
    end
    for i = 1, maxStars do
        local b = create("TextButton", { Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = 18, Text = "★", AutoButtonColor = false, Parent = row })
        local sc = create("UIScale", { Scale = 1, Parent = b })
        b.MouseEnter:Connect(function() tween(sc, { Scale = 1.18 }, Flow.Anim.HoverTime) end)
        b.MouseLeave:Connect(function() tween(sc, { Scale = 1 }, Flow.Anim.ReleaseTime, Flow.Anim.EasingSpring) end)
        b.MouseButton1Click:Connect(function() val = i; render(); if opts.Callback then opts.Callback(val) end end)
        table.insert(btns, b)
    end
    render()
    return { Instance = row, Get = function() return val end }
end

function ContainerMethods:Input(opts)
    opts = opts or {}
    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, opts.Label and 58 or 36), BackgroundTransparency = 1, Parent = self._frame })
    addList(holder, Enum.FillDirection.Vertical, 4)
    if opts.Label then
        create("TextLabel", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Flow.Fonts.sans, TextSize = 12, TextColor3 = Flow.Theme.foreground, Text = opts.Label, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })
    end
    local boxFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 36), Parent = holder })
    addCorner(boxFrame, Flow.Radius.md)
    local _, rim = applyLiquidGlass(boxFrame, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.ControlTransparency })
    addPadding(boxFrame, 0, 10, 0, 10)
    local tb = create("TextBox", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        PlaceholderColor3 = Flow.Theme.muted,
        PlaceholderText = opts.Placeholder or "Enter text...",
        Text = opts.Default or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = boxFrame,
    })
    tb.Focused:Connect(function() tween(rim, { Transparency = 0.05 }, Flow.Anim.HoverTime) end)
    tb.FocusLost:Connect(function(enter)
        tween(rim, { Transparency = Flow.Glass.RimTransparency }, Flow.Anim.HoverTime)
        if opts.Callback then opts.Callback(tb.Text, enter) end
    end)
    return { Instance = holder, TextBox = tb, Get = function() return tb.Text end, Set = function(_, v) tb.Text = tostring(v) end }
end
function ContainerMethods:TextField(opts) return self:Input(opts) end
function ContainerMethods:SearchField(opts) opts = opts or {}; opts.Placeholder = opts.Placeholder or "Search..."; return self:Input(opts) end

function ContainerMethods:InputGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 36), Parent = self._frame })
    addCorner(row, Flow.Radius.md)
    applyLiquidGlass(row, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.ControlTransparency })
    addPadding(row, 0, 10, 0, 10)
    addList(row, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    create("TextLabel", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34), BackgroundTransparency = 1, Font = Flow.Fonts.mono, TextSize = 12, TextColor3 = Flow.Theme.muted, Text = opts.Prefix or "https://", Parent = row })
    local tb = create("TextBox", { Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 13, TextColor3 = Flow.Theme.foreground, PlaceholderText = opts.Placeholder or "heroui.com", Text = "", TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    return { Instance = row, TextBox = tb }
end

function ContainerMethods:TextArea(opts)
    opts = opts or {}
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, opts.Height or 84), Parent = self._frame })
    addCorner(box, Flow.Radius.md)
    applyLiquidGlass(box, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.ControlTransparency })
    addPadding(box, 8, 10, 8, 10)
    local tb = create("TextBox", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 13, TextColor3 = Flow.Theme.foreground, PlaceholderColor3 = Flow.Theme.muted, PlaceholderText = opts.Placeholder or "Write a message...", Text = opts.Default or "", MultiLine = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, Parent = box })
    tb.FocusLost:Connect(function() if opts.Callback then opts.Callback(tb.Text) end end)
    return { Instance = box, TextBox = tb, Get = function() return tb.Text end }
end

function ContainerMethods:NumberField(opts)
    opts = opts or {}
    local val = opts.Default or 0
    local step = opts.Step or 1
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 36), Parent = self._frame })
    addCorner(row, Flow.Radius.md)
    applyLiquidGlass(row, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.ControlTransparency })
    addPadding(row, 0, 8, 0, 10)
    local lbl = create("TextLabel", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 13, TextColor3 = Flow.Theme.foreground, Text = opts.Label or "Number", TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    local ctrl = create("Frame", { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Parent = row })
    addList(ctrl, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local valTxt = create("TextLabel", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(32, 24), BackgroundTransparency = 1, Font = Flow.Fonts.mono, TextSize = 13, TextColor3 = Flow.Theme.foreground, Text = tostring(val), Parent = ctrl })
    local minus = create("TextButton", { Size = UDim2.fromOffset(24, 24), Font = Flow.Fonts.bold, TextSize = 14, TextColor3 = Flow.Theme.foreground, Text = "-", AutoButtonColor = false, ClipsDescendants = true, Parent = ctrl })
    addCorner(minus, Flow.Radius.sm)
    applyLiquidGlass(minus, { Tint = Flow.Theme.defaultSoft, Transparency = 0.25 })
    attachGlassInteraction(minus, { BaseTransparency = 0.25 })
    local plus = create("TextButton", { Size = UDim2.fromOffset(24, 24), Font = Flow.Fonts.bold, TextSize = 14, TextColor3 = Flow.Theme.foreground, Text = "+", AutoButtonColor = false, ClipsDescendants = true, Parent = ctrl })
    addCorner(plus, Flow.Radius.sm)
    applyLiquidGlass(plus, { Tint = Flow.Theme.defaultSoft, Transparency = 0.25 })
    attachGlassInteraction(plus, { BaseTransparency = 0.25 })
    minus.MouseButton1Click:Connect(function() val = val - step; valTxt.Text = tostring(val); if opts.Callback then opts.Callback(val) end end)
    plus.MouseButton1Click:Connect(function() val = val + step; valTxt.Text = tostring(val); if opts.Callback then opts.Callback(val) end end)
    return { Instance = row, Label = lbl, Get = function() return val end }
end
function ContainerMethods:NumberStepper(opts) return self:NumberField(opts) end
function ContainerMethods:NumberValue(opts) opts = opts or {}; return self:Typography({ Text = tostring(opts.Value or "1,024"), Variant = "h2", Mono = true }) end

function ContainerMethods:InputOtp(opts)
    opts = opts or {}
    local len = opts.Length or 4
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 8)
    local boxes = {}
    for i = 1, len do
        local tb = create("TextBox", { Size = UDim2.fromOffset(38, 40), Font = Flow.Fonts.mono, TextSize = 16, TextColor3 = Flow.Theme.foreground, Text = "", PlaceholderText = "•", Parent = row })
        addCorner(tb, Flow.Radius.md)
        applyLiquidGlass(tb, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.ControlTransparency })
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            if #tb.Text > 1 then tb.Text = string.sub(tb.Text, 1, 1) end
            if #tb.Text == 1 and boxes[i + 1] then boxes[i + 1]:CaptureFocus() end
        end)
        boxes[i] = tb
    end
    return { Instance = row, Get = function() local s = "" for _, b in ipairs(boxes) do s = s .. b.Text end return s end }
end

function ContainerMethods:Fieldset(opts) opts = opts or {}; return self:Card({ Title = opts.Legend or "Fieldset", Description = opts.Description }) end
function ContainerMethods:Form(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Form" })
    if opts.OnSubmit then card:Button({ Text = opts.SubmitText or "Submit", Callback = opts.OnSubmit }) end
    return card
end

function ContainerMethods:DropZone(opts)
    opts = opts or {}
    local dz = create("TextButton", { Size = UDim2.new(1, 0, 0, 80), Font = Flow.Fonts.regular, TextSize = 12, TextColor3 = Flow.Theme.muted, Text = opts.Text or "Click or drop files here", AutoButtonColor = false, ClipsDescendants = true, Parent = self._frame })
    addCorner(dz, Flow.Radius.lg)
    applyLiquidGlass(dz, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
    attachGlassInteraction(dz, { BaseTransparency = Flow.Glass.SurfaceTransparency })
    if opts.Callback then dz.MouseButton1Click:Connect(opts.Callback) end
    return { Instance = dz }
end

function ContainerMethods:RichTextEditor(opts)
    opts = opts or {}
    local box = self:Surface({ Padding = 8, Gap = 6 })
    box:Toolbar({ Actions = { "B", "I", "U", "Link" } })
    box:TextArea({ Placeholder = opts.Placeholder or "Rich text content...", Height = 80 })
    return box
end

function ContainerMethods:CodeBlock(opts)
    opts = opts or {}
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = self._frame })
    addCorner(box, Flow.Radius.md)
    applyLiquidGlass(box, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.28 })
    addPadding(box, 10, 12, 10, 12)
    local lbl = create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Flow.Fonts.mono, TextSize = 12, TextColor3 = Flow.Theme.accentSoftForeground, Text = opts.Code or "print('Hello FlowUI')", TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = box })
    return { Instance = box, SetCode = function(_, c) lbl.Text = tostring(c) end }
end

function ContainerMethods:Markdown(opts) opts = opts or {}; return self:Typography({ Text = opts.Text or "# Markdown Heading\nRendered cleanly in FlowUI.", Variant = "body" }) end

--============================================================================--
-- SECTION 3: SELECTION, MENUS, NAVIGATION & DISCLOSURE
--============================================================================--

function ContainerMethods:Select(opts)
    opts = opts or {}
    local items = opts.Items or { "Option 1", "Option 2", "Option 3" }
    local selected = opts.Default or items[1]
    local open = false

    local wrapper = create("Frame", { Size = UDim2.new(1, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self._frame })
    addList(wrapper, Enum.FillDirection.Vertical, 4)

    local trigger = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = "  " .. (opts.Label and (opts.Label .. ": ") or "") .. tostring(selected) .. "  ▾",
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = wrapper,
    })
    addCorner(trigger, Flow.Radius.md)
    applyLiquidGlass(trigger, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.ControlTransparency })
    attachGlassInteraction(trigger, { BaseTransparency = Flow.Glass.ControlTransparency })

    local menu = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = wrapper })
    addCorner(menu, Flow.Radius.md)
    applyLiquidGlass(menu, { Tint = Flow.Theme.overlay, Transparency = Flow.Glass.OverlayTransparency })
    addPadding(menu, 4)
    addList(menu, Enum.FillDirection.Vertical, 2)
    local menuScale = create("UIScale", { Scale = 0.96, Parent = menu })

    for _, item in ipairs(items) do
        local opt = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Flow.Theme.accentSoft,
            BackgroundTransparency = 1,
            Font = Flow.Fonts.regular,
            TextSize = 12,
            TextColor3 = Flow.Theme.foreground,
            Text = "  " .. tostring(item),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ClipsDescendants = true,
            Parent = menu,
        })
        addCorner(opt, Flow.Radius.sm)
        opt.MouseEnter:Connect(function() tween(opt, { BackgroundTransparency = 0.25 }, Flow.Anim.HoverTime) end)
        opt.MouseLeave:Connect(function() tween(opt, { BackgroundTransparency = 1 }, Flow.Anim.HoverTime) end)
        opt.MouseButton1Click:Connect(function()
            selected = item
            open = false
            menu.Visible = false
            trigger.Text = "  " .. (opts.Label and (opts.Label .. ": ") or "") .. tostring(selected) .. "  ▾"
            if opts.Callback then opts.Callback(selected) end
        end)
    end

    trigger.MouseButton1Click:Connect(function()
        open = not open
        menu.Visible = open
        if open then
            menuScale.Scale = 0.96
            tween(menuScale, { Scale = 1 }, Flow.Anim.SpringTime, Flow.Anim.EasingSpring)
        end
    end)

    return { Instance = wrapper, Get = function() return selected end }
end
function ContainerMethods:NativeSelect(opts) return self:Select(opts) end
function ContainerMethods:InlineSelect(opts) return self:Select(opts) end
function ContainerMethods:Autocomplete(opts) return self:Select(opts) end
function ContainerMethods:ComboBox(opts) return self:Select(opts) end
function ContainerMethods:Dropdown(opts) return self:Select(opts) end

function ContainerMethods:ListBox(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "ListBox" })
    local items = opts.Items or { "Item 1", "Item 2", "Item 3" }
    local selected = nil
    for _, item in ipairs(items) do
        local b = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            Font = Flow.Fonts.regular,
            TextSize = 13,
            TextColor3 = Flow.Theme.foreground,
            Text = "  " .. tostring(item),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ClipsDescendants = true,
            Parent = card._frame,
        })
        addCorner(b, Flow.Radius.sm)
        applyLiquidGlass(b, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.55, RimThickness = 0 })
        attachGlassInteraction(b, { BaseTransparency = 0.55 })
        b.MouseButton1Click:Connect(function() selected = item; if opts.Callback then opts.Callback(item) end end)
    end
    return { Card = card, Get = function() return selected end }
end
function ContainerMethods:ListView(opts) return self:ListBox(opts) end

function ContainerMethods:ContextMenu(opts)
    opts = opts or {}
    local target = self:Surface({ Padding = 12 })
    target:Typography({ Text = opts.Text or "Right-click here for Liquid Glass ContextMenu", Variant = "caption" })
    local items = opts.Items or { "Copy", "Paste", "Delete" }

    target._frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Flow:_ensureRoot()
            for _, c in ipairs(Flow._overlayLayer:GetChildren()) do
                if c.Name == "FlowContextMenu" then c:Destroy() end
            end
            local menu = create("Frame", {
                Name = "FlowContextMenu",
                Size = UDim2.fromOffset(168, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.fromOffset(input.Position.X, input.Position.Y),
                ZIndex = 250,
                Parent = Flow._overlayLayer,
            })
            addCorner(menu, Flow.Radius.md)
            applyLiquidGlass(menu, { Tint = Flow.Theme.overlay, Transparency = Flow.Glass.OverlayTransparency })
            addPadding(menu, 4)
            addList(menu, Enum.FillDirection.Vertical, 2)
            local sc = create("UIScale", { Scale = 0.92, Parent = menu })
            tween(sc, { Scale = 1 }, Flow.Anim.SpringTime, Flow.Anim.EasingSpring)
            for _, item in ipairs(items) do
                local b = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = Flow.Theme.accentSoft,
                    BackgroundTransparency = 1,
                    Font = Flow.Fonts.regular,
                    TextSize = 12,
                    TextColor3 = Flow.Theme.foreground,
                    Text = "  " .. item,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 251,
                    Parent = menu,
                })
                addCorner(b, Flow.Radius.sm)
                b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = 0.25 }, Flow.Anim.HoverTime) end)
                b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 1 }, Flow.Anim.HoverTime) end)
                b.MouseButton1Click:Connect(function() menu:Destroy(); if opts.Callback then opts.Callback(item) end end)
            end
        end
    end)
    return target
end

function Flow:Command(opts)
    opts = opts or {}
    self:_ensureRoot()
    self:_setWorldBlur(true)
    local overlay = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 260, Parent = self._overlayLayer })
    tween(overlay, { BackgroundTransparency = 0.45 }, self.Anim.FadeTime)
    local box = create("Frame", { Size = UDim2.fromOffset(420, 260), Position = UDim2.new(0.5, -210, 0.35, -130), ZIndex = 261, Parent = overlay })
    addCorner(box, self.Radius.xl)
    applyLiquidGlass(box, { Tint = self.Theme.overlay, Transparency = self.Glass.OverlayTransparency, RimThickness = 1.4 })
    local sc = create("UIScale", { Scale = 0.92, Parent = box })
    tween(sc, { Scale = 1 }, self.Anim.SpringTime, self.Anim.EasingSpring)
    addPadding(box, 12)
    addList(box, Enum.FillDirection.Vertical, 8)
    local w = wrapContainer(box)
    w:Input({ Placeholder = opts.Placeholder or "Type a command...", Callback = function() end })
    local function close()
        self:_setWorldBlur(false)
        tween(overlay, { BackgroundTransparency = 1 }, self.Anim.FadeTime)
        tween(sc, { Scale = 0.92 }, self.Anim.PressTime)
        task.delay(self.Anim.FadeTime, function() if overlay.Parent then overlay:Destroy() end end)
    end
    for _, item in ipairs(opts.Items or { "Toggle Theme", "Reload Config", "Close" }) do
        w:Button({ Text = item, Variant = "ghost", Size = UDim2.new(1, 0, 0, 30), Callback = function()
            close(); if opts.Callback then opts.Callback(item) end
        end })
    end
    w:Button({ Text = "Close Palette", Color = "danger", Variant = "soft", Size = UDim2.new(1, 0, 0, 30), Callback = close })
    return { Overlay = overlay }
end
function ContainerMethods:Command(opts) return Flow:Command(opts) end

function ContainerMethods:Tabs(opts)
    opts = opts or {}
    local items = opts.Items or { "Tab 1", "Tab 2", "Tab 3" }
    local active = opts.Default or items[1]
    local bar = create("Frame", { Size = UDim2.new(1, 0, 0, 38), Parent = self._frame })
    addCorner(bar, Flow.Radius.md)
    applyLiquidGlass(bar, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.32 })
    addPadding(bar, 4)

    local pill = create("Frame", {
        Size = UDim2.new(1 / #items, -4, 1, 0),
        Position = UDim2.fromScale(0, 0),
        ZIndex = 1,
        Parent = bar,
    })
    addCorner(pill, Flow.Radius.sm)
    applyLiquidGlass(pill, { Tint = Flow.Theme.surface, Transparency = 0.14 })

    local row = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = bar })
    addList(row, Enum.FillDirection.Horizontal, 0)
    local btns = {}
    for i, item in ipairs(items) do
        local b = create("TextButton", {
            Size = UDim2.new(1 / #items, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Flow.Fonts.sans,
            TextSize = 12,
            TextColor3 = (item == active) and Flow.Theme.foreground or Flow.Theme.muted,
            Text = item,
            AutoButtonColor = false,
            ZIndex = 3,
            Parent = row,
        })
        btns[item] = { btn = b, idx = i }
        b.MouseButton1Click:Connect(function()
            active = item
            tween(pill, { Position = UDim2.new((i - 1) / #items, 0, 0, 0) }, Flow.Anim.SpringTime, Flow.Anim.EasingSpring)
            for k, info in pairs(btns) do
                tween(info.btn, { TextColor3 = (k == active) and Flow.Theme.foreground or Flow.Theme.muted }, Flow.Anim.HoverTime)
            end
            if opts.Callback then opts.Callback(item) end
        end)
    end
    return { Instance = bar, Get = function() return active end }
end
function ContainerMethods:Segment(opts) return self:Tabs(opts) end

function ContainerMethods:Breadcrumbs(opts)
    opts = opts or {}
    local items = opts.Items or { "Home", "Library", "Components" }
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    for i, item in ipairs(items) do
        create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = (i == #items) and Flow.Fonts.bold or Flow.Fonts.regular, TextSize = 12, TextColor3 = (i == #items) and Flow.Theme.foreground or Flow.Theme.muted, Text = item, Parent = row })
        if i < #items then
            create("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 12, TextColor3 = Flow.Theme.muted, Text = "/", Parent = row })
        end
    end
    return { Instance = row }
end

function ContainerMethods:Pagination(opts)
    opts = opts or {}
    local total = opts.Total or 5
    local page = opts.Default or 1
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6)
    local btns = {}
    local function render()
        for i, b in ipairs(btns) do
            tween(b, {
                BackgroundColor3 = (i == page) and Flow.Theme.accent or Flow.Theme.defaultSoft,
                TextColor3 = (i == page) and Flow.Theme.accentForeground or Flow.Theme.foreground,
            }, Flow.Anim.HoverTime)
        end
    end
    for i = 1, total do
        local b = create("TextButton", { Size = UDim2.fromOffset(28, 28), Font = Flow.Fonts.sans, TextSize = 12, Text = tostring(i), AutoButtonColor = false, ClipsDescendants = true, Parent = row })
        addCorner(b, Flow.Radius.sm)
        applyLiquidGlass(b, { Tint = Flow.Theme.defaultSoft, Transparency = 0.25 })
        attachGlassInteraction(b, { BaseTransparency = 0.25 })
        btns[i] = b
        b.MouseButton1Click:Connect(function() page = i; render(); if opts.Callback then opts.Callback(page) end end)
    end
    render()
    return { Instance = row, Get = function() return page end }
end

function ContainerMethods:Stepper(opts)
    opts = opts or {}
    local steps = opts.Steps or { "Step 1", "Step 2", "Step 3" }
    local current = opts.Current or 1
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    for i, s in ipairs(steps) do
        local done = i <= current
        local chip = create("TextLabel", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), Font = Flow.Fonts.sans, TextSize = 11, TextColor3 = done and Flow.Theme.accentSoftForeground or Flow.Theme.muted, Text = tostring(i) .. ". " .. s, Parent = row })
        addCorner(chip, Flow.Radius.full)
        applyLiquidGlass(chip, { Tint = done and Flow.Theme.accentSoft or Flow.Theme.surfaceSecondary, Transparency = 0.25 })
        addPadding(chip, 0, 10, 0, 10)
    end
    return { Instance = row }
end

function ContainerMethods:Disclosure(opts)
    opts = opts or {}
    local open = opts.DefaultOpen or false
    local card = self:Surface({ Padding = 10, Gap = 6 })
    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = (open and "▾ " or "▸ ") .. (opts.Title or "Disclosure"),
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = card._frame,
    })
    local body = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = open, Parent = card._frame })
    addList(body, Enum.FillDirection.Vertical, 6)
    header.MouseButton1Click:Connect(function()
        open = not open
        body.Visible = open
        header.Text = (open and "▾ " or "▸ ") .. (opts.Title or "Disclosure")
    end)
    local bw = wrapContainer(body)
    if opts.Content then bw:Typography({ Text = opts.Content, Variant = "caption" }) end
    return bw
end
function ContainerMethods:Accordion(opts) return self:Disclosure(opts) end
function ContainerMethods:DisclosureGroup(opts)
    opts = opts or {}
    local box = self:Surface({ Padding = 8, Gap = 6 })
    for _, item in ipairs(opts.Items or {
        { Title = "What is FlowUI?", Content = "A HeroUI Liquid Glass Roblox UI framework." },
        { Title = "Are animations unified?", Content = "Yes, every component shares Flow.Anim." },
    }) do box:Disclosure(item) end
    return box
end

function ContainerMethods:TagGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6)
    local w = wrapContainer(row)
    for _, t in ipairs(opts.Tags or { "React", "HeroUI", "Luau" }) do w:Chip({ Text = t, Variant = "soft", Color = opts.Color or "default" }) end
    return w
end

function ContainerMethods:FileTree(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "File Tree" })
    for _, path in ipairs(opts.Files or { "src/", "  Flow.lua", "  main.lua", "use.txt" }) do
        card:Typography({ Text = path, Mono = true, Variant = "small" })
    end
    return card
end

--============================================================================--
-- SECTION 4: OVERLAYS, FEEDBACK, DATE/TIME & COLOR
--============================================================================--

function ContainerMethods:Alert(opts)
    opts = opts or {}
    local bg, fg = getColorPair(opts.Color or "accent", "soft")
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = self._frame })
    addCorner(box, Flow.Radius.md)
    applyLiquidGlass(box, { Tint = bg, Transparency = 0.22 })
    addPadding(box, 10, 14, 10, 14)
    addList(box, Enum.FillDirection.Vertical, 2)
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = 13, TextColor3 = fg, Text = opts.Title or "Notice", TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = box })
    if opts.Description then
        create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 12, TextColor3 = Flow.Theme.foreground, Text = opts.Description, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = box })
    end
    return { Instance = box }
end

function Flow:Toast(opts)
    opts = opts or {}
    self:_ensureRoot()
    local bg, fg = getColorPair(opts.Color or "default", "soft")
    local toast = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 310, Parent = self._toastLayer })
    addCorner(toast, self.Radius.lg)
    applyLiquidGlass(toast, { Tint = bg, Transparency = self.Glass.OverlayTransparency, RimThickness = 1.3 })
    local sc = create("UIScale", { Scale = 0.88, Parent = toast })
    tween(sc, { Scale = 1 }, self.Anim.SpringTime, self.Anim.EasingSpring)
    addPadding(toast, 10, 14, 10, 14)
    addList(toast, Enum.FillDirection.Vertical, 3)

    create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = self.Fonts.bold, TextSize = 13, TextColor3 = fg, Text = opts.Title or "Notification", TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 311, Parent = toast })
    if opts.Description then
        create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = self.Fonts.regular, TextSize = 12, TextColor3 = self.Theme.muted, Text = opts.Description, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 311, Parent = toast })
    end
    task.delay(opts.Duration or 3.5, function()
        if toast and toast.Parent then
            tween(sc, { Scale = 0.88 }, self.Anim.PressTime)
            tween(toast, { BackgroundTransparency = 1 }, self.Anim.FadeTime)
            task.delay(self.Anim.FadeTime, function() if toast.Parent then toast:Destroy() end end)
        end
    end)
    return { Instance = toast }
end
function ContainerMethods:Toast(opts) return Flow:Toast(opts) end

function Flow:Modal(opts)
    opts = opts or {}
    self:_ensureRoot()
    self:_setWorldBlur(true)
    local backdrop = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 240, Parent = self._overlayLayer })
    tween(backdrop, { BackgroundTransparency = 0.45 }, self.Anim.FadeTime)
    local wSize = opts.Size or UDim2.fromOffset(380, 0)
    local card = create("Frame", { Size = wSize, AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0.5, -(wSize.X.Offset / 2), 0.5, -110), ZIndex = 241, Parent = backdrop })
    addCorner(card, self.Radius.xl)
    applyLiquidGlass(card, { Tint = self.Theme.overlay, Transparency = self.Glass.OverlayTransparency, RimThickness = 1.5 })
    local sc = create("UIScale", { Scale = 0.90, Parent = card })
    tween(sc, { Scale = 1 }, self.Anim.SpringTime, self.Anim.EasingSpring)
    addPadding(card, 16)
    addList(card, Enum.FillDirection.Vertical, 10)

    local function close()
        self:_setWorldBlur(false)
        tween(backdrop, { BackgroundTransparency = 1 }, self.Anim.FadeTime)
        tween(sc, { Scale = 0.90 }, self.Anim.PressTime)
        task.delay(self.Anim.FadeTime, function() if backdrop.Parent then backdrop:Destroy() end end)
    end

    local w = wrapContainer(card)
    w:Typography({ Text = opts.Title or "Modal Dialog", Variant = "h3" })
    if opts.Description then w:Description({ Text = opts.Description }) end
    local actions = create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = card })
    addList(actions, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local aw = wrapContainer(actions)
    aw:Button({ Text = opts.CancelText or "Cancel", Variant = "soft", Color = "default", Size = UDim2.fromOffset(90, 32), Callback = function() close(); if opts.OnCancel then opts.OnCancel() end end })
    aw:Button({ Text = opts.ConfirmText or "Confirm", Color = opts.Color or "accent", Size = UDim2.fromOffset(100, 32), Callback = function() close(); if opts.OnConfirm then opts.OnConfirm() end end })
    return { Backdrop = backdrop, Body = w }
end
function ContainerMethods:Modal(opts) return Flow:Modal(opts) end
function Flow:AlertDialog(opts) opts = opts or {}; opts.Color = opts.Color or "danger"; opts.ConfirmText = opts.ConfirmText or "Delete"; return self:Modal(opts) end
function ContainerMethods:AlertDialog(opts) return Flow:AlertDialog(opts) end

function Flow:Drawer(opts)
    opts = opts or {}
    self:_ensureRoot()
    self:_setWorldBlur(true)
    local backdrop = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 240, Parent = self._overlayLayer })
    tween(backdrop, { BackgroundTransparency = 0.45 }, self.Anim.FadeTime)
    local width = opts.Width or 300
    local panel = create("Frame", { Size = UDim2.new(0, width, 1, 0), Position = UDim2.new(1, 0, 0, 0), ZIndex = 241, Parent = backdrop })
    applyLiquidGlass(panel, { Tint = self.Theme.overlay, Transparency = self.Glass.OverlayTransparency, RimThickness = 1.4 })
    addPadding(panel, 16)
    addList(panel, Enum.FillDirection.Vertical, 10)
    tween(panel, { Position = UDim2.new(1, -width, 0, 0) }, self.Anim.SlideTime, self.Anim.EasingSmooth)
    local w = wrapContainer(panel)
    w:Typography({ Text = opts.Title or "Drawer", Variant = "h3" })
    if opts.Description then w:Description({ Text = opts.Description }) end
    w:Button({ Text = "Close Drawer", Variant = "soft", Color = "default", Callback = function()
        self:_setWorldBlur(false)
        tween(panel, { Position = UDim2.new(1, 0, 0, 0) }, self.Anim.SlideTime)
        tween(backdrop, { BackgroundTransparency = 1 }, self.Anim.FadeTime)
        task.delay(self.Anim.SlideTime, function() if backdrop.Parent then backdrop:Destroy() end end)
    end })
    return w
end
function ContainerMethods:Drawer(opts) return Flow:Drawer(opts) end
function Flow:Sheet(opts) return self:Drawer(opts) end
function ContainerMethods:Sheet(opts) return Flow:Drawer(opts) end

function ContainerMethods:Popover(opts)
    opts = opts or {}
    local open = false
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self._frame })
    addList(box, Enum.FillDirection.Vertical, 6)
    local w = wrapContainer(box)
    local pop = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = box })
    addCorner(pop, Flow.Radius.md)
    applyLiquidGlass(pop, { Tint = Flow.Theme.overlay, Transparency = Flow.Glass.OverlayTransparency })
    addPadding(pop, 10)
    addList(pop, Enum.FillDirection.Vertical, 6)
    local sc = create("UIScale", { Scale = 0.96, Parent = pop })
    w:Button({ Text = opts.TriggerText or "Toggle Popover", Variant = "soft", Color = "default", Callback = function()
        open = not open
        pop.Visible = open
        if open then sc.Scale = 0.96; tween(sc, { Scale = 1 }, Flow.Anim.SpringTime, Flow.Anim.EasingSpring) end
    end })
    local pw = wrapContainer(pop)
    if opts.Content then pw:Typography({ Text = opts.Content, Variant = "small" }) end
    return pw
end
function ContainerMethods:HoverCard(opts) return self:Popover(opts) end
function ContainerMethods:Tooltip(opts)
    opts = opts or {}
    local lbl = self:Chip({ Text = opts.Text or "Hover me for Tooltip", Variant = "outline" })
    Flow:_attachTooltip(lbl.Instance, opts.Tip or "HeroUI Liquid Glass Tooltip")
    return lbl
end

function ContainerMethods:ProgressBar(opts)
    opts = opts or {}
    local val = math.clamp(opts.Value or 60, 0, 100)
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = self._frame })
    addList(box, Enum.FillDirection.Vertical, 4)
    if opts.Label then
        create("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Flow.Fonts.regular, TextSize = 12, TextColor3 = Flow.Theme.foreground, Text = opts.Label .. " (" .. tostring(val) .. "%)", TextXAlignment = Enum.TextXAlignment.Left, Parent = box })
    end
    local track = create("Frame", { Size = UDim2.new(1, 0, 0, 8), Parent = box })
    addCorner(track, Flow.Radius.full)
    applyLiquidGlass(track, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.28 })
    local fill = create("Frame", { Size = UDim2.new(val / 100, 0, 1, 0), BackgroundColor3 = Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent, Parent = track })
    addCorner(fill, Flow.Radius.full)
    return { Instance = box, Set = function(_, v) val = math.clamp(v, 0, 100); tween(fill, { Size = UDim2.new(val / 100, 0, 1, 0) }, Flow.Anim.HoverTime) end }
end
function ContainerMethods:Meter(opts) return self:ProgressBar(opts) end

function ContainerMethods:ProgressCircle(opts)
    opts = opts or {}
    local val = math.clamp(opts.Value or 75, 0, 100)
    local sz = opts.Size or 48
    local ring = create("Frame", { Size = UDim2.fromOffset(sz, sz), Parent = self._frame })
    addCorner(ring, Flow.Radius.full)
    applyLiquidGlass(ring, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.22 })
    create("UIStroke", { Color = Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent, Thickness = 3.5, Parent = ring })
    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = 12, TextColor3 = Flow.Theme.foreground, Text = tostring(val) .. "%", Parent = ring })
    return { Instance = ring }
end

function ContainerMethods:Calendar(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Month or "November 2026" })
    local grid = create("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1, Parent = card._frame })
    create("UIGridLayout", { CellSize = UDim2.fromOffset(30, 26), CellPadding = UDim2.fromOffset(4, 4), Parent = grid })
    local sel = opts.Default or 15
    for d = 1, 30 do
        local b = create("TextButton", {
            Font = Flow.Fonts.sans,
            TextSize = 11,
            TextColor3 = (d == sel) and Flow.Theme.accentForeground or Flow.Theme.foreground,
            Text = tostring(d),
            AutoButtonColor = false,
            ClipsDescendants = true,
            Parent = grid,
        })
        addCorner(b, Flow.Radius.sm)
        applyLiquidGlass(b, { Tint = (d == sel) and Flow.Theme.accent or Flow.Theme.surfaceSecondary, Transparency = 0.25 })
        attachGlassInteraction(b, { BaseTransparency = 0.25 })
        b.MouseButton1Click:Connect(function() sel = d; if opts.Callback then opts.Callback(d) end end)
    end
    return card
end
function ContainerMethods:RangeCalendar(opts) return self:Calendar(opts) end
function ContainerMethods:DateField(opts) opts = opts or {}; opts.Placeholder = opts.Placeholder or "YYYY-MM-DD"; opts.Label = opts.Label or "Date"; return self:Input(opts) end
function ContainerMethods:DatePicker(opts) return self:DateField(opts) end
function ContainerMethods:DateRangePicker(opts) opts = opts or {}; opts.Placeholder = "2026-11-01 -> 2026-11-30"; opts.Label = opts.Label or "Date Range"; return self:Input(opts) end
function ContainerMethods:TimeField(opts) opts = opts or {}; opts.Placeholder = "14:30"; opts.Label = opts.Label or "Time"; return self:Input(opts) end

function ContainerMethods:Agenda(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Agenda" })
    for _, ev in ipairs(opts.Events or { "09:00 — Standup", "13:00 — Design Review", "16:30 — Release" }) do
        card:Chip({ Text = ev, Variant = "soft", Color = "accent" })
    end
    return card
end

function ContainerMethods:Timeline(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Timeline" })
    for _, item in ipairs(opts.Items or { "Initialized FlowUI", "Added Liquid Glass Engine", "Ready for Executor" }) do
        card:Typography({ Text = "●  " .. item, Variant = "small" })
    end
    return card
end

function ContainerMethods:ColorSwatch(opts)
    opts = opts or {}
    local sw = create("Frame", { Size = UDim2.fromOffset(24, 24), Parent = self._frame })
    addCorner(sw, Flow.Radius.sm)
    applyLiquidGlass(sw, { Tint = opts.Color or Flow.Theme.accent, Transparency = 0.1 })
    return { Instance = sw }
end

function ContainerMethods:ColorSwatchPicker(opts)
    opts = opts or {}
    local colors = opts.Colors or {
        Color3.fromRGB(0, 111, 238),
        Color3.fromRGB(23, 201, 100),
        Color3.fromRGB(245, 165, 36),
        Color3.fromRGB(243, 18, 96),
        Color3.fromRGB(147, 83, 211),
    }
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 8)
    for _, c in ipairs(colors) do
        local b = create("TextButton", { Size = UDim2.fromOffset(24, 24), Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = row })
        addCorner(b, Flow.Radius.full)
        applyLiquidGlass(b, { Tint = c, Transparency = 0.1 })
        attachGlassInteraction(b, { BaseTransparency = 0.1 })
        b.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback(c) end end)
    end
    return { Instance = row }
end

function ContainerMethods:ColorArea(opts)
    opts = opts or {}
    local area = create("TextButton", { Size = UDim2.new(1, 0, 0, 90), Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = self._frame })
    addCorner(area, Flow.Radius.md)
    applyLiquidGlass(area, { Tint = Color3.fromRGB(0, 111, 238), Transparency = 0.15 })
    attachGlassInteraction(area, { BaseTransparency = 0.15 })
    area.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback(Flow.Theme.accent) end end)
    return { Instance = area }
end

function ContainerMethods:ColorSlider(opts)
    opts = opts or {}
    return self:Slider({ Label = opts.Label or "Hue", Min = 0, Max = 360, Default = 210, Callback = function(h)
        if opts.Callback then opts.Callback(Color3.fromHSV(h / 360, 0.85, 0.95)) end
    end })
end
function ContainerMethods:ColorField(opts) opts = opts or {}; opts.Label = opts.Label or "Hex Color"; opts.Placeholder = "#006FEE"; return self:Input(opts) end
function ContainerMethods:ColorPicker(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Label or "Color Picker" })
    card:ColorSwatchPicker({ Callback = opts.Callback })
    card:ColorSlider({ Callback = opts.Callback })
    return card
end

function ContainerMethods:EmojiPicker(opts)
    opts = opts or {}
    local emojis = opts.Emojis or { "👍", "❤️", "🔥", "🚀", "✨", "🎉" }
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6)
    for _, em in ipairs(emojis) do
        local b = create("TextButton", { Size = UDim2.fromOffset(30, 30), Text = em, TextSize = 15, AutoButtonColor = false, ClipsDescendants = true, Parent = row })
        addCorner(b, Flow.Radius.sm)
        applyLiquidGlass(b, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.25 })
        attachGlassInteraction(b, { BaseTransparency = 0.25 })
        b.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback(em) end end)
    end
    return { Instance = row }
end

function ContainerMethods:EmojiReactionButton(opts)
    opts = opts or {}
    local count = opts.Count or 1
    local btn = self:Button({ Text = (opts.Emoji or "🔥") .. " " .. tostring(count), Variant = "soft", Color = "default", Size = UDim2.fromOffset(68, 28) })
    btn.Instance.MouseButton1Click:Connect(function() count = count + 1; btn:SetText((opts.Emoji or "🔥") .. " " .. tostring(count)) end)
    return btn
end

--============================================================================--
-- SECTION 5: DATA DISPLAY, TABLES, CHARTS & AI/CHAT
--============================================================================--

function ContainerMethods:Table(opts)
    opts = opts or {}
    local cols = opts.Columns or { "Name", "Role", "Status" }
    local rows = opts.Rows or {
        { "Tony", "CEO", "Active" },
        { "Zoey", "Tech Lead", "Active" },
        { "Jane", "Designer", "Paused" },
    }
    local card = self:Surface({ Padding = 10, Gap = 4 })
    local function makeRow(cells, isHeader)
        local r = create("Frame", { Size = UDim2.new(1, 0, 0, 28), Parent = card._frame })
        addCorner(r, Flow.Radius.sm)
        applyLiquidGlass(r, { Tint = isHeader and Flow.Theme.surfaceSecondary or Flow.Theme.surface, Transparency = isHeader and 0.24 or 0.45, RimThickness = 0 })
        addList(r, Enum.FillDirection.Horizontal, 0)
        for _, cell in ipairs(cells) do
            create("TextLabel", { Size = UDim2.new(1 / #cells, 0, 1, 0), BackgroundTransparency = 1, Font = isHeader and Flow.Fonts.bold or Flow.Fonts.regular, TextSize = 12, TextColor3 = isHeader and Flow.Theme.muted or Flow.Theme.foreground, Text = "  " .. tostring(cell), TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
        end
    end
    makeRow(cols, true)
    for _, row in ipairs(rows) do makeRow(row, false) end
    return card
end
function ContainerMethods:DataGrid(opts) return self:Table(opts) end
function ContainerMethods:CellColorPicker(opts) return self:ColorSwatchPicker(opts) end
function ContainerMethods:CellSelect(opts) return self:Select(opts) end
function ContainerMethods:CellSlider(opts) return self:Slider(opts) end
function ContainerMethods:CellSwitch(opts) return self:Switch(opts) end

function ContainerMethods:Kpi(opts)
    opts = opts or {}
    local card = self:Surface({ Padding = 12, Gap = 4 })
    card:Description({ Text = opts.Title or "Total Revenue" })
    card:Typography({ Text = tostring(opts.Value or "$45,231.89"), Variant = "h2", Mono = true })
    card:TrendChip({ Value = opts.Delta or "+20.1%", Direction = opts.Direction or "up" })
    return card
end

function ContainerMethods:KpiGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self._frame })
    create("UIGridLayout", { CellSize = UDim2.new(0.48, 0, 0, 108), CellPadding = UDim2.fromOffset(10, 10), Parent = row })
    local w = wrapContainer(row)
    for _, k in ipairs(opts.Items or {
        { Title = "Active Users", Value = "12,480", Delta = "+14.2%", Direction = "up" },
        { Title = "Latency", Value = "24ms", Delta = "-4.1%", Direction = "up" },
    }) do w:Kpi(k) end
    return w
end

function ContainerMethods:Kanban(opts)
    opts = opts or {}
    local cols = opts.Columns or {
        { Title = "To Do", Cards = { "Liquid Glass", "Executor test" } },
        { Title = "In Progress", Cards = { "HeroUI parity" } },
        { Title = "Done", Cards = { "Flow.Anim" } },
    }
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 10)
    for _, col in ipairs(cols) do
        local c = create("Frame", { Size = UDim2.new(1 / #cols, -7, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row })
        addCorner(c, Flow.Radius.md)
        applyLiquidGlass(c, { Tint = Flow.Theme.surface, Transparency = Flow.Glass.SurfaceTransparency })
        addPadding(c, 8)
        addList(c, Enum.FillDirection.Vertical, 6)
        local cw = wrapContainer(c)
        cw:Label({ Text = col.Title })
        for _, cardTitle in ipairs(col.Cards or {}) do cw:Chip({ Text = cardTitle, Variant = "soft", Color = "default" }) end
    end
    return { Instance = row }
end

function ContainerMethods:Carousel(opts)
    opts = opts or {}
    local slides = opts.Slides or { "Slide 1: Liquid Glass UI", "Slide 2: 142 HeroUI Components", "Slide 3: Unified Flow.Anim" }
    local idx = 1
    local card = self:Card({ Title = opts.Title or "Carousel" })
    local lbl = card:Typography({ Text = slides[idx], Variant = "h4" })
    local nav = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = card._frame })
    addList(nav, Enum.FillDirection.Horizontal, 8)
    local nw = wrapContainer(nav)
    nw:Button({ Text = "Prev", Variant = "soft", Color = "default", Size = UDim2.fromOffset(70, 28), Callback = function() idx = ((idx - 2) % #slides) + 1; lbl:SetText(slides[idx]) end })
    nw:Button({ Text = "Next", Variant = "soft", Color = "accent", Size = UDim2.fromOffset(70, 28), Callback = function() idx = (idx % #slides) + 1; lbl:SetText(slides[idx]) end })
    return card
end

function ContainerMethods:Map(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Map Viewport", Description = opts.Location or "San Francisco, CA" })
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, 90), Parent = card._frame })
    addCorner(box, Flow.Radius.md)
    applyLiquidGlass(box, { Tint = Flow.Theme.accentSoft, Transparency = 0.22 })
    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Flow.Fonts.bold, TextSize = 16, TextColor3 = Flow.Theme.accentSoftForeground, Text = "📍 " .. (opts.Location or "Map Marker"), Parent = box })
    return card
end

function ContainerMethods:BarChart(opts)
    opts = opts or {}
    local data = opts.Data or { 35, 65, 48, 90, 72, 55, 84 }
    local card = self:Card({ Title = opts.Title or "Bar Chart" })
    local plot = create("Frame", { Size = UDim2.new(1, 0, 0, 110), Parent = card._frame })
    addCorner(plot, Flow.Radius.md)
    applyLiquidGlass(plot, { Tint = Flow.Theme.surfaceSecondary, Transparency = 0.30 })
    addPadding(plot, 10)
    addList(plot, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)
    local maxV = 1
    for _, v in ipairs(data) do if v > maxV then maxV = v end end
    for _, v in ipairs(data) do
        local bar = create("Frame", { Size = UDim2.new(1 / #data, -8, 0, 0), Parent = plot })
        addCorner(bar, Flow.Radius.sm)
        applyLiquidGlass(bar, { Tint = Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent, Transparency = 0.16 })
        tween(bar, { Size = UDim2.new(1 / #data, -8, v / maxV, 0) }, Flow.Anim.SpringTime, Flow.Anim.EasingSpring)
        Flow:_attachTooltip(bar, "Value: " .. tostring(v))
    end
    return card
end
function ContainerMethods:AreaChart(opts) opts = opts or {}; opts.Title = opts.Title or "Area Chart"; opts.Color = opts.Color or "success"; return self:BarChart(opts) end
function ContainerMethods:LineChart(opts) opts = opts or {}; opts.Title = opts.Title or "Line Chart"; return self:BarChart(opts) end
function ContainerMethods:ComposedChart(opts) opts = opts or {}; opts.Title = opts.Title or "Composed Chart"; return self:BarChart(opts) end
function ContainerMethods:PieChart(opts) opts = opts or {}; local card = self:Card({ Title = opts.Title or "Pie Chart" }); card:ProgressCircle({ Value = opts.Value or 68, Size = 64, Color = "accent" }); return card end
function ContainerMethods:RadialChart(opts) opts = opts or {}; opts.Title = opts.Title or "Radial Chart"; return self:PieChart(opts) end
function ContainerMethods:RadarChart(opts) opts = opts or {}; opts.Title = opts.Title or "Radar Chart"; return self:BarChart(opts) end
function ContainerMethods:ChartTooltip(opts) opts = opts or {}; return self:Chip({ Text = opts.Text or "Jan: 420 pts", Color = "accent", Variant = "soft" }) end

function ContainerMethods:ApprovalCard(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Approval Required", Description = opts.Description or "Allow agent to execute action?" })
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = card._frame })
    addList(row, Enum.FillDirection.Horizontal, 8)
    local rw = wrapContainer(row)
    rw:Button({ Text = "Approve", Color = "success", Size = UDim2.fromOffset(90, 30), Callback = opts.OnApprove })
    rw:Button({ Text = "Reject", Color = "danger", Variant = "soft", Size = UDim2.fromOffset(90, 30), Callback = opts.OnReject })
    return card
end

function ContainerMethods:ChainOfThought(opts) opts = opts or {}; return self:Disclosure({ Title = opts.Title or "Chain of Thought", Content = opts.Content or "1. Parsed request\n2. Built Liquid Glass\n3. Rendered UI", DefaultOpen = false }) end
function ContainerMethods:Reasoning(opts) opts = opts or {}; opts.Title = opts.Title or "Reasoning"; return self:ChainOfThought(opts) end
function ContainerMethods:ChatAttachment(opts) opts = opts or {}; return self:Chip({ Text = "📎 " .. (opts.Name or "attachment.lua"), Variant = "outline" }) end
function ContainerMethods:ChatLoader(opts) opts = opts or {}; return self:TextShimmer({ Text = opts.Text or "Assistant is typing..." }) end
function ContainerMethods:ChatSource(opts) opts = opts or {}; return self:Link({ Text = "🔗 Source: " .. (opts.Title or "heroui.com/docs") }) end
function ContainerMethods:ChatTool(opts) opts = opts or {}; return self:Chip({ Text = "⚙ Tool: " .. (opts.Name or "read_file"), Color = "warning", Variant = "soft" }) end
function ContainerMethods:ChatMessageActions(opts) opts = opts or {}; return self:Toolbar({ Actions = opts.Actions or { "Copy", "Retry", "👍", "👎" }, Callback = opts.Callback }) end

function ContainerMethods:ChatMessage(opts)
    opts = opts or {}
    local isUser = (opts.Role == "user")
    local box = self:Surface({ Background = isUser and "accentSoft" or "surface", Padding = 10, Gap = 4 })
    box:Label({ Text = isUser and "You" or (opts.Sender or "Assistant"), Size = 11, Color = isUser and "accentSoftForeground" or "muted" })
    box:Typography({ Text = opts.Text or "Hello! How can I help you today?", Variant = "body" })
    return box
end

function ContainerMethods:ChatConversation(opts)
    opts = opts or {}
    local box = self:ScrollShadow({ Height = opts.Height or 160 })
    for _, msg in ipairs(opts.Messages or {
        { Role = "user", Text = "Add Liquid Glass to Flow.lua." },
        { Role = "assistant", Text = "Done! Liquid Glass + unified animations are live." },
    }) do box:ChatMessage(msg) end
    return box
end

function ContainerMethods:ChatListView(opts) opts = opts or {}; return self:ListBox({ Title = opts.Title or "Conversations", Items = opts.Items or { "Liquid Glass", "Theme Tokens", "Executor Script" } }) end
function ContainerMethods:ModelSelector(opts) opts = opts or {}; return self:Select({ Label = "Model", Items = opts.Models or { "Gemini 4", "Claude Sonnet", "GPT-5" }, Callback = opts.Callback }) end
function ContainerMethods:PromptSuggestion(opts) opts = opts or {}; return self:Chip({ Text = "✨ " .. (opts.Text or "Generate Roblox UI"), Color = "accent", Variant = "soft" }) end

function ContainerMethods:PromptInput(opts)
    opts = opts or {}
    local box = self:Surface({ Padding = 8, Gap = 6 })
    local inp = box:Input({ Placeholder = opts.Placeholder or "Ask anything...", Callback = function(txt, enter)
        if enter and opts.OnSubmit then opts.OnSubmit(txt) end
    end })
    box:Button({ Text = "Send", Size = UDim2.fromOffset(80, 30), Callback = function()
        if opts.OnSubmit then opts.OnSubmit(inp:Get()) end
    end })
    return box
end

return Flow
