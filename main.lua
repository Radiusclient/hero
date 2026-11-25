--[[
    FlowUI (Flow.lua) — HeroUI-Inspired Roblox Executor UI Framework
    Version: 1.0.0
    Architecture:
      - Full HeroUI v3 Semantic Token & Theme System (Dark / Light + Custom Overrides)
      - Executor-Safe Mounting (gethui -> CoreGui -> PlayerGui)
      - Smooth TweenService Micro-Interactions & Ripple/PressableFeedback
      - 142 HeroUI Components across Layout, Navigation, Forms, Data Display,
        Charts, AI/Chat, Color/Date/Time, Overlays, and Feedback.
      - Designed for GitHub raw + loadstring(game:HttpGet("..."))()
]]

local Flow = {}
Flow.__index = Flow
Flow.Version = "1.0.0"

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

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

--// HeroUI v3 Theme Tokens (Dark & Light)
Flow.Themes = {
    dark = {
        background = Color3.fromRGB(9, 9, 11),         -- zinc-950
        foreground = Color3.fromRGB(250, 250, 250),    -- zinc-50
        muted = Color3.fromRGB(161, 161, 170),         -- zinc-400
        surface = Color3.fromRGB(24, 24, 27),          -- zinc-900
        surfaceSecondary = Color3.fromRGB(39, 39, 42), -- zinc-800
        overlay = Color3.fromRGB(24, 24, 27),
        border = Color3.fromRGB(46, 46, 52),
        divider = Color3.fromRGB(39, 39, 42),

        default = Color3.fromRGB(63, 63, 70),
        defaultForeground = Color3.fromRGB(250, 250, 250),
        defaultSoft = Color3.fromRGB(39, 39, 42),
        defaultSoftForeground = Color3.fromRGB(212, 212, 216),

        accent = Color3.fromRGB(0, 111, 238),          -- HeroUI Blue
        accentForeground = Color3.fromRGB(255, 255, 255),
        accentSoft = Color3.fromRGB(16, 42, 76),
        accentSoftForeground = Color3.fromRGB(102, 170, 255),

        success = Color3.fromRGB(23, 201, 100),
        successForeground = Color3.fromRGB(0, 0, 0),
        successSoft = Color3.fromRGB(13, 56, 33),
        successSoftForeground = Color3.fromRGB(69, 212, 131),

        warning = Color3.fromRGB(245, 165, 36),
        warningForeground = Color3.fromRGB(0, 0, 0),
        warningSoft = Color3.fromRGB(66, 45, 12),
        warningSoftForeground = Color3.fromRGB(247, 183, 80),

        danger = Color3.fromRGB(243, 18, 96),
        dangerForeground = Color3.fromRGB(255, 255, 255),
        dangerSoft = Color3.fromRGB(68, 12, 33),
        dangerSoftForeground = Color3.fromRGB(248, 113, 160),
    },
    light = {
        background = Color3.fromRGB(255, 255, 255),
        foreground = Color3.fromRGB(17, 24, 28),
        muted = Color3.fromRGB(113, 113, 122),
        surface = Color3.fromRGB(244, 244, 245),
        surfaceSecondary = Color3.fromRGB(228, 228, 231),
        overlay = Color3.fromRGB(255, 255, 255),
        border = Color3.fromRGB(212, 212, 216),
        divider = Color3.fromRGB(228, 228, 231),

        default = Color3.fromRGB(212, 212, 216),
        defaultForeground = Color3.fromRGB(17, 24, 28),
        defaultSoft = Color3.fromRGB(244, 244, 245),
        defaultSoftForeground = Color3.fromRGB(63, 63, 70),

        accent = Color3.fromRGB(0, 111, 238),
        accentForeground = Color3.fromRGB(255, 255, 255),
        accentSoft = Color3.fromRGB(224, 238, 255),
        accentSoftForeground = Color3.fromRGB(0, 91, 196),

        success = Color3.fromRGB(23, 201, 100),
        successForeground = Color3.fromRGB(255, 255, 255),
        successSoft = Color3.fromRGB(222, 249, 233),
        successSoftForeground = Color3.fromRGB(14, 121, 60),

        warning = Color3.fromRGB(245, 165, 36),
        warningForeground = Color3.fromRGB(0, 0, 0),
        warningSoft = Color3.fromRGB(254, 243, 220),
        warningSoftForeground = Color3.fromRGB(147, 99, 22),

        danger = Color3.fromRGB(243, 18, 96),
        dangerForeground = Color3.fromRGB(255, 255, 255),
        dangerSoft = Color3.fromRGB(254, 224, 235),
        dangerSoftForeground = Color3.fromRGB(146, 11, 58),
    },
}

Flow.ActiveThemeName = "dark"
Flow.Theme = {}
for k, v in pairs(Flow.Themes.dark) do
    Flow.Theme[k] = v
end
Flow._themeListeners = {}

Flow.Radius = {
    none = 0,
    sm = 6,
    md = 10,
    lg = 14,
    xl = 18,
    full = 999,
}

Flow.Fonts = {
    sans = Enum.Font.GothamMedium,
    bold = Enum.Font.GothamBold,
    regular = Enum.Font.Gotham,
    mono = Enum.Font.RobotoMono,
}

--// Utility Functions
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
    local info = TweenInfo.new(
        duration or 0.18,
        style or Enum.EasingStyle.Quint,
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

local function addStroke(inst, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Flow.Theme.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
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
        return Color3.new(0, 0, 0), base, base
    elseif variant == "ghost" or variant == "light" then
        return Color3.new(0, 0, 0), softFg, base
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

--// Shared ScreenGui & Overlay Root
function Flow:_ensureRoot()
    if self._screenGui and self._screenGui.Parent then
        return self._screenGui
    end
    local gui = create("ScreenGui", {
        Name = "FlowUI_Root",
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
        Size = UDim2.new(0, 340, 1, -32),
        Position = UDim2.new(1, -356, 0, 16),
        BackgroundTransparency = 1,
        ZIndex = 300,
        Parent = gui,
    })
    addList(self._toastLayer, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

    self._tooltipBox = create("Frame", {
        Name = "Tooltip",
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = self.Theme.surfaceSecondary,
        Visible = false,
        ZIndex = 400,
        Parent = gui,
    })
    addCorner(self._tooltipBox, self.Radius.sm)
    addStroke(self._tooltipBox, self.Theme.border, 1)
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

function Flow:Destroy()
    if self._screenGui then
        self._screenGui:Destroy()
        self._screenGui = nil
    end
end

--// Attach Tooltip Helper
function Flow:_attachTooltip(target, text)
    self:_ensureRoot()
    local hovering = false
    target.MouseEnter:Connect(function()
        hovering = true
        self._tooltipLabel.Text = tostring(text)
        self._tooltipBox.BackgroundColor3 = self.Theme.surfaceSecondary
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

--// Component Registry & Container Wrapper
local ContainerMethods = {}
ContainerMethods.__index = ContainerMethods

local function wrapContainer(frame)
    return setmetatable({
        Instance = frame,
        _frame = frame,
    }, ContainerMethods)
end

--// Window / App Shell
function Flow:CreateWindow(opts)
    opts = opts or {}
    self:_ensureRoot()

    local title = opts.Title or "FlowUI"
    local subtitle = opts.Subtitle or "HeroUI for Roblox"
    local size = opts.Size or UDim2.fromOffset(820, 540)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightControl

    local winFrame = create("Frame", {
        Name = "FlowWindow",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = self.Theme.background,
        ClipsDescendants = true,
        Parent = self._screenGui,
    })
    addCorner(winFrame, self.Radius.xl)
    local winStroke = addStroke(winFrame, self.Theme.border, 1)

    -- Header / Navbar
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = self.Theme.surface,
        BorderSizePixel = 0,
        Parent = winFrame,
    })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = self.Theme.divider,
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
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = self.Theme.accent,
        Parent = brandBox,
    })
    addCorner(logoBadge, self.Radius.sm)
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

    -- Right Header Actions (Theme toggle + Close)
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
        BackgroundColor3 = self.Theme.defaultSoft,
        Font = self.Fonts.sans,
        TextSize = 11,
        TextColor3 = self.Theme.defaultSoftForeground,
        Text = "Theme: " .. self.ActiveThemeName,
        AutoButtonColor = false,
        Parent = actionsBox,
    })
    addCorner(themeBtn, self.Radius.sm)
    addPadding(themeBtn, 0, 10, 0, 10)
    themeBtn.MouseButton1Click:Connect(function()
        local nextTheme = (self.ActiveThemeName == "dark") and "light" or "dark"
        self:SetTheme(nextTheme)
        themeBtn.Text = "Theme: " .. nextTheme
    end)

    local closeBtn = create("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = self.Theme.defaultSoft,
        Font = self.Fonts.bold,
        TextSize = 13,
        TextColor3 = self.Theme.muted,
        Text = "X",
        AutoButtonColor = false,
        Parent = actionsBox,
    })
    addCorner(closeBtn, self.Radius.sm)
    closeBtn.MouseButton1Click:Connect(function()
        winFrame.Visible = not winFrame.Visible
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == toggleKey then
            winFrame.Visible = not winFrame.Visible
        end
    end)

    -- Body: Sidebar + Content Area
    local body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -52),
        Position = UDim2.fromOffset(0, 52),
        BackgroundTransparency = 1,
        Parent = winFrame,
    })

    local sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 190, 1, 0),
        BackgroundColor3 = self.Theme.surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = body,
    })
    addPadding(sidebar, 12, 10, 12, 10)
    addList(sidebar, Enum.FillDirection.Vertical, 4)

    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.fromOffset(190, 0),
        BackgroundColor3 = self.Theme.divider,
        BorderSizePixel = 0,
        Parent = body,
    })

    local contentHolder = create("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -191, 1, 0),
        Position = UDim2.fromOffset(191, 0),
        BackgroundTransparency = 1,
        Parent = body,
    })

    onThemeChange(function(t)
        winFrame.BackgroundColor3 = t.background
        winStroke.Color = t.border
        header.BackgroundColor3 = t.surface
        sidebar.BackgroundColor3 = t.surface
        titleLbl.TextColor3 = t.foreground
        subLbl.TextColor3 = t.muted
        themeBtn.BackgroundColor3 = t.defaultSoft
        themeBtn.TextColor3 = t.defaultSoftForeground
        closeBtn.BackgroundColor3 = t.defaultSoft
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
            Parent = sidebar,
        })
        addCorner(tabBtn, Flow.Radius.md)

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
                tween(t.Button, { BackgroundTransparency = 1, TextColor3 = Flow.Theme.muted }, 0.14)
            end
            page.Visible = true
            tween(tabBtn, { BackgroundTransparency = 0, BackgroundColor3 = Flow.Theme.accentSoft, TextColor3 = Flow.Theme.accentSoftForeground }, 0.14)
            Window._activeTab = tabObj
        end

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
        if state == nil then
            winFrame.Visible = not winFrame.Visible
        else
            winFrame.Visible = state
        end
    end

    return Window
end

--============================================================================--
-- SECTION 1: PRIMITIVES, LAYOUT, TYPOGRAPHY & CARDS
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
    return {
        Instance = lbl,
        SetText = function(_, t) lbl.Text = tostring(t) end,
    }
end

function ContainerMethods:Label(opts)
    opts = opts or {}
    return self:Typography({
        Text = opts.Text or "Label",
        Variant = "h4",
        Size = opts.Size or 13,
        Color = opts.Color or "foreground",
    })
end

function ContainerMethods:Description(opts)
    opts = opts or {}
    return self:Typography({
        Text = opts.Text or "Helper description text.",
        Variant = "caption",
        Size = opts.Size or 12,
        Color = "muted",
    })
end

function ContainerMethods:ErrorMessage(opts)
    opts = opts or {}
    return self:Typography({
        Text = opts.Text or "Invalid input value.",
        Variant = "caption",
        Size = 12,
        Color = "dangerSoftForeground",
    })
end

function ContainerMethods:FieldError(opts)
    return self:ErrorMessage(opts)
end

function ContainerMethods:Separator(opts)
    opts = opts or {}
    local vertical = opts.Orientation == "vertical"
    local line = create("Frame", {
        Size = vertical and UDim2.new(0, 1, 0, opts.Length or 24) or UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Flow.Theme.divider,
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
        BackgroundColor3 = Flow.Theme[opts.Background or "surface"] or Flow.Theme.surface,
        Parent = self._frame,
    })
    addCorner(card, Flow.Radius[opts.Radius or "lg"] or Flow.Radius.lg)
    if opts.Border ~= false then
        addStroke(card, Flow.Theme.border, 1)
    end
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
        BackgroundColor3 = Flow.Theme.surface,
        Text = "",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.lg)
    addStroke(btn, Flow.Theme.border, 1)
    addPadding(btn, 10, 14, 10, 14)

    local row = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = btn })
    addList(row, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local iconBox = create("Frame", {
        Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = Flow.Theme.accentSoft,
        Parent = row,
    })
    addCorner(iconBox, Flow.Radius.md)
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

    btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Flow.Theme.surfaceSecondary }, 0.12) end)
    btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = Flow.Theme.surface }, 0.12) end)
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
        for _, item in ipairs(opts.Items) do
            wrapper:ItemCard(item)
        end
    end
    return wrapper
end

function ContainerMethods:HoloCard(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "HoloCard", Description = opts.Description or "Interactive gradient card" })
    local grad = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Flow.Theme.accentSoft),
            ColorSequenceKeypoint.new(0.5, Flow.Theme.surface),
            ColorSequenceKeypoint.new(1, Flow.Theme.dangerSoft),
        }),
        Rotation = 35,
        Parent = card._frame,
    })
    card._frame.MouseMoved:Connect(function(x, y)
        grad.Rotation = ((x + y) % 360)
    end)
    return card
end

function ContainerMethods:EmptyState(opts)
    opts = opts or {}
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, opts.Height or 140),
        BackgroundColor3 = Flow.Theme.surface,
        Parent = self._frame,
    })
    addCorner(box, Flow.Radius.lg)
    addStroke(box, Flow.Theme.border, 1)
    addList(box, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 22,
        TextColor3 = Flow.Theme.muted,
        Text = opts.Icon or "∅",
        Parent = box,
    })
    create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 14,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Title or "No data available",
        Parent = box,
    })
    create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 12,
        TextColor3 = Flow.Theme.muted,
        Text = opts.Description or "Items will appear here once created.",
        Parent = box,
    })
    return wrapContainer(box)
end

function ContainerMethods:Skeleton(opts)
    opts = opts or {}
    local sk = create("Frame", {
        Size = opts.Size or UDim2.new(1, 0, 0, opts.Height or 20),
        BackgroundColor3 = Flow.Theme.surfaceSecondary,
        Parent = self._frame,
    })
    addCorner(sk, Flow.Radius[opts.Radius or "md"] or Flow.Radius.md)
    task.spawn(function()
        while sk and sk.Parent do
            tween(sk, { BackgroundTransparency = 0.55 }, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.75)
            if not (sk and sk.Parent) then break end
            tween(sk, { BackgroundTransparency = 0 }, 0.7, Enum.EasingStyle.Sine)
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
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, sz + 6),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    addList(holder, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local ring = create("Frame", {
        Size = UDim2.fromOffset(sz, sz),
        BackgroundTransparency = 1,
        Parent = holder,
    })
    addCorner(ring, Flow.Radius.full)
    local stroke = addStroke(ring, Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent, 2.5)
    local grad = create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.85),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = stroke,
    })
    local conn = RunService.RenderStepped:Connect(function(dt)
        if not ring.Parent then return end
        grad.Rotation = (grad.Rotation + dt * 360) % 360
    end)
    ring.Destroying:Connect(function() conn:Disconnect() end)
    if opts.Label then
        create("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Font = Flow.Fonts.regular,
            TextSize = 12,
            TextColor3 = Flow.Theme.muted,
            Text = opts.Label,
            Parent = holder,
        })
    end
    return { Instance = holder }
end

function ContainerMethods:Loader(opts)
    return self:Spinner(opts)
end

function ContainerMethods:Kbd(opts)
    opts = opts or {}
    local kbd = create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 22),
        BackgroundColor3 = Flow.Theme.surfaceSecondary,
        Font = Flow.Fonts.mono,
        TextSize = 11,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Text or "Ctrl + K",
        Parent = self._frame,
    })
    addCorner(kbd, Flow.Radius.sm)
    addStroke(kbd, Flow.Theme.border, 1)
    addPadding(kbd, 2, 7, 2, 7)
    return { Instance = kbd }
end

function ContainerMethods:Chip(opts)
    opts = opts or {}
    local bg, fg, border = getColorPair(opts.Color or "default", opts.Variant or "soft")
    local chip = create("TextButton", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 24),
        BackgroundColor3 = (opts.Variant == "outline") and Flow.Theme.background or bg,
        Font = Flow.Fonts.sans,
        TextSize = 11,
        TextColor3 = fg,
        Text = opts.Text or "Chip",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(chip, Flow.Radius.full)
    addPadding(chip, 0, 10, 0, 10)
    if opts.Variant == "outline" then
        addStroke(chip, border, 1)
    end
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
    return self:Chip({
        Text = opts.Text or "New",
        Color = opts.Color or "accent",
        Variant = opts.Variant or "solid",
    })
end

function ContainerMethods:TrendChip(opts)
    opts = opts or {}
    local up = (opts.Direction or "up") == "up"
    return self:Chip({
        Text = (up and "▲ " or "▼ ") .. tostring(opts.Value or "+12.5%"),
        Color = up and "success" or "danger",
        Variant = "soft",
    })
end

function ContainerMethods:Avatar(opts)
    opts = opts or {}
    local sz = opts.Size or 36
    local bg, fg = getColorPair(opts.Color or "accent", "soft")
    local av = create("Frame", {
        Size = UDim2.fromOffset(sz, sz),
        BackgroundColor3 = bg,
        Parent = self._frame,
    })
    addCorner(av, Flow.Radius.full)
    addStroke(av, Flow.Theme.border, 1)
    if opts.Image then
        local img = create("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = opts.Image,
            Parent = av,
        })
        addCorner(img, Flow.Radius.full)
    else
        create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Font = Flow.Fonts.bold,
            TextSize = math.floor(sz * 0.4),
            TextColor3 = fg,
            Text = opts.Initials or "FL",
            Parent = av,
        })
    end
    return { Instance = av }
end

function ContainerMethods:AvatarGroup(opts)
    opts = opts or {}
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    addList(row, Enum.FillDirection.Horizontal, -8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    local w = wrapContainer(row)
    for _, item in ipairs(opts.Items or { { Initials = "A" }, { Initials = "B" }, { Initials = "C" } }) do
        w:Avatar(item)
    end
    return w
end

function ContainerMethods:Link(opts)
    opts = opts or {}
    local btn = create("TextButton", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.sans,
        TextSize = opts.Size or 13,
        TextColor3 = Flow.Theme.accent,
        Text = opts.Text or "External Link ↗",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    btn.MouseButton1Click:Connect(function()
        if opts.Url and type(setclipboard) == "function" then
            pcall(setclipboard, opts.Url)
        end
        if opts.Callback then opts.Callback() end
    end)
    return { Instance = btn }
end

function ContainerMethods:CloseButton(opts)
    opts = opts or {}
    local btn = create("TextButton", {
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Flow.Theme.defaultSoft,
        Font = Flow.Fonts.bold,
        TextSize = 12,
        TextColor3 = Flow.Theme.muted,
        Text = "×",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.full)
    if opts.Callback then btn.MouseButton1Click:Connect(opts.Callback) end
    return { Instance = btn }
end

function ContainerMethods:PressableFeedback(opts)
    opts = opts or {}
    local btn = create("TextButton", {
        Size = opts.Size or UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Flow.Theme.surface,
        Font = Flow.Fonts.sans,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Text or "Press Me (Scale Feedback)",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.md)
    addStroke(btn, Flow.Theme.border, 1)
    local sc = create("UIScale", { Scale = 1, Parent = btn })
    btn.MouseButton1Down:Connect(function() tween(sc, { Scale = 0.96 }, 0.08) end)
    btn.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, 0.12) end)
    btn.MouseLeave:Connect(function() tween(sc, { Scale = 1 }, 0.12) end)
    if opts.Callback then btn.MouseButton1Click:Connect(opts.Callback) end
    return { Instance = btn }
end

function ContainerMethods:ScrollShadow(opts)
    opts = opts or {}
    local sc = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, opts.Height or 110),
        BackgroundColor3 = Flow.Theme.surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self._frame,
    })
    addCorner(sc, Flow.Radius.md)
    addStroke(sc, Flow.Theme.border, 1)
    addPadding(sc, 10)
    addList(sc, Enum.FillDirection.Vertical, 6)
    return wrapContainer(sc)
end

function ContainerMethods:Resizable(opts)
    opts = opts or {}
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, opts.Height or 100),
        BackgroundColor3 = Flow.Theme.surface,
        Parent = self._frame,
    })
    addCorner(box, Flow.Radius.md)
    addStroke(box, Flow.Theme.border, 1)
    local left = create("Frame", {
        Size = UDim2.new(0.5, -2, 1, 0),
        BackgroundColor3 = Flow.Theme.surfaceSecondary,
        Parent = box,
    })
    addCorner(left, Flow.Radius.sm)
    local right = create("Frame", {
        Size = UDim2.new(0.5, -2, 1, 0),
        Position = UDim2.new(0.5, 2, 0, 0),
        BackgroundColor3 = Flow.Theme.surface,
        Parent = box,
    })
    local handle = create("TextButton", {
        Size = UDim2.new(0, 6, 1, 0),
        Position = UDim2.new(0.5, -3, 0, 0),
        BackgroundColor3 = Flow.Theme.accent,
        Text = "",
        AutoButtonColor = false,
        Parent = box,
    })
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
    local bar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Flow.Theme.surface,
        Parent = self._frame,
    })
    addCorner(bar, Flow.Radius.md)
    addStroke(bar, Flow.Theme.border, 1)
    addPadding(bar, 0, 12, 0, 12)
    addList(bar, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 24),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Brand or "HeroUI",
        Parent = bar,
    })
    local w = wrapContainer(bar)
    for _, item in ipairs(opts.Items or { "Home", "Docs", "Settings" }) do
        w:Chip({ Text = item, Variant = "ghost" })
    end
    return w
end

function ContainerMethods:Sidebar(opts)
    opts = opts or {}
    local box = self:Surface({ Padding = 10, Gap = 4 })
    for _, item in ipairs(opts.Items or { "Dashboard", "Analytics", "Users" }) do
        local b = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Flow.Theme.defaultSoft,
            BackgroundTransparency = 1,
            Font = Flow.Fonts.sans,
            TextSize = 12,
            TextColor3 = Flow.Theme.foreground,
            Text = "  " .. item,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = box._frame,
        })
        addCorner(b, Flow.Radius.sm)
        b.MouseButton1Click:Connect(function()
            if opts.Callback then opts.Callback(item) end
        end)
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
    local bar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Flow.Theme.surface,
        Parent = self._frame,
    })
    addCorner(bar, Flow.Radius.md)
    addStroke(bar, Flow.Theme.border, 1)
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

function ContainerMethods:ActionBar(opts)
    return self:Toolbar(opts)
end

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
    return self:Card({ Title = opts.Title or "Widget", Description = opts.Description or "Composable widget container" })
end

--============================================================================--
-- SECTION 2: BUTTONS, TOGGLES & FORMS / INPUTS
--============================================================================--

function ContainerMethods:Button(opts)
    opts = opts or {}
    local bg, fg, border = getColorPair(opts.Color or "accent", opts.Variant or "solid")
    local btn = create("TextButton", {
        Size = opts.Size or UDim2.new(0, 140, 0, 36),
        BackgroundColor3 = (opts.Variant == "outline" or opts.Variant == "ghost") and Flow.Theme.surface or bg,
        BackgroundTransparency = (opts.Variant == "ghost") and 1 or 0,
        Font = Flow.Fonts.sans,
        TextSize = 13,
        TextColor3 = fg,
        Text = opts.IsPending and "Loading..." or (opts.Text or "Button"),
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius[opts.Radius or "md"] or Flow.Radius.md)
    if opts.Variant == "outline" then
        addStroke(btn, border, 1)
    end
    local sc = create("UIScale", { Scale = 1, Parent = btn })
    btn.MouseButton1Down:Connect(function() tween(sc, { Scale = 0.96 }, 0.08) end)
    btn.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, 0.1) end)
    btn.MouseLeave:Connect(function() tween(sc, { Scale = 1 }, 0.1) end)
    if opts.Tooltip then Flow:_attachTooltip(btn, opts.Tooltip) end
    btn.MouseButton1Click:Connect(function()
        if not opts.IsDisabled and opts.Callback then
            opts.Callback()
        end
    end)
    return {
        Instance = btn,
        SetText = function(_, t) btn.Text = tostring(t) end,
    }
end

function ContainerMethods:ButtonGroup(opts)
    opts = opts or {}
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
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
        BackgroundColor3 = selected and Flow.Theme.accent or Flow.Theme.defaultSoft,
        Font = Flow.Fonts.sans,
        TextSize = 12,
        TextColor3 = selected and Flow.Theme.accentForeground or Flow.Theme.defaultSoftForeground,
        Text = opts.Text or "Toggle",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(btn, Flow.Radius.md)
    local function render()
        tween(btn, {
            BackgroundColor3 = selected and Flow.Theme.accent or Flow.Theme.defaultSoft,
            TextColor3 = selected and Flow.Theme.accentForeground or Flow.Theme.defaultSoftForeground,
        }, 0.14)
    end
    btn.MouseButton1Click:Connect(function()
        selected = not selected
        render()
        if opts.Callback then opts.Callback(selected) end
    end)
    return {
        Instance = btn,
        Get = function() return selected end,
        Set = function(_, v) selected = v; render() end,
    }
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
    local box = create("Frame", {
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = checked and Flow.Theme.accent or Flow.Theme.surfaceSecondary,
        Parent = row,
    })
    addCorner(box, 5)
    local stroke = addStroke(box, checked and Flow.Theme.accent or Flow.Theme.border, 1.5)
    local mark = create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 12,
        TextColor3 = Flow.Theme.accentForeground,
        Text = checked and "✓" or "",
        Parent = box,
    })
    create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Label or "Checkbox",
        Parent = row,
    })
    local function render()
        tween(box, { BackgroundColor3 = checked and Flow.Theme.accent or Flow.Theme.surfaceSecondary }, 0.14)
        stroke.Color = checked and Flow.Theme.accent or Flow.Theme.border
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
        card:Checkbox({
            Label = item,
            Callback = function(v)
                state[item] = v
                if opts.Callback then opts.Callback(state) end
            end,
        })
    end
    return card
end

function ContainerMethods:CheckboxButtonGroup(opts)
    return self:ToggleButtonGroup(opts)
end

function ContainerMethods:RadioGroup(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Label or "Radio Group" })
    local selected = opts.Default or (opts.Items and opts.Items[1]) or "Option 1"
    local dots = {}
    for _, item in ipairs(opts.Items or { "Option 1", "Option 2", "Option 3" }) do
        local row = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = card._frame,
        })
        addList(row, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
        local outer = create("Frame", {
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Flow.Theme.surfaceSecondary,
            Parent = row,
        })
        addCorner(outer, Flow.Radius.full)
        local st = addStroke(outer, item == selected and Flow.Theme.accent or Flow.Theme.border, 1.5)
        local inner = create("Frame", {
            Size = UDim2.fromOffset(8, 8),
            Position = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Flow.Theme.accent,
            Visible = (item == selected),
            Parent = outer,
        })
        addCorner(inner, Flow.Radius.full)
        create("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Font = Flow.Fonts.regular,
            TextSize = 13,
            TextColor3 = Flow.Theme.foreground,
            Text = item,
            Parent = row,
        })
        dots[item] = { inner = inner, stroke = st }
        row.MouseButton1Click:Connect(function()
            selected = item
            for k, d in pairs(dots) do
                d.inner.Visible = (k == selected)
                d.stroke.Color = (k == selected) and Flow.Theme.accent or Flow.Theme.border
            end
            if opts.Callback then opts.Callback(selected) end
        end)
    end
    return { Card = card, Get = function() return selected end }
end

function ContainerMethods:RadioButtonGroup(opts)
    return self:Segment(opts)
end

function ContainerMethods:Switch(opts)
    opts = opts or {}
    local on = opts.Default or false
    local row = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, -54, 1, 0),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Label or "Switch",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local track = create("Frame", {
        Size = UDim2.fromOffset(42, 24),
        Position = UDim2.new(1, -42, 0.5, -12),
        BackgroundColor3 = on and Flow.Theme.accent or Flow.Theme.default,
        Parent = row,
    })
    addCorner(track, Flow.Radius.full)
    local thumb = create("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = track,
    })
    addCorner(thumb, Flow.Radius.full)
    local function render()
        tween(track, { BackgroundColor3 = on and Flow.Theme.accent or Flow.Theme.default }, 0.16)
        tween(thumb, { Position = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) }, 0.16)
    end
    row.MouseButton1Click:Connect(function()
        on = not on
        render()
        if opts.Callback then opts.Callback(on) end
    end)
    return { Instance = row, Label = lbl, Get = function() return on end, Set = function(_, v) on = v; render() end }
end

function ContainerMethods:Slider(opts)
    opts = opts or {}
    local minV = opts.Min or 0
    local maxV = opts.Max or 100
    local val = math.clamp(opts.Default or minV, minV, maxV)

    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    local top = create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = box })
    create("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 12,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Label or "Slider",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = top,
    })
    local valLbl = create("TextLabel", {
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.mono,
        TextSize = 12,
        TextColor3 = Flow.Theme.muted,
        Text = tostring(val),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = top,
    })
    local track = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.fromOffset(0, 26),
        BackgroundColor3 = Flow.Theme.surfaceSecondary,
        Text = "",
        AutoButtonColor = false,
        Parent = box,
    })
    addCorner(track, Flow.Radius.full)
    local pct = (val - minV) / math.max(1e-5, maxV - minV)
    local fill = create("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Flow.Theme.accent,
        Parent = track,
    })
    addCorner(fill, Flow.Radius.full)
    local knob = create("Frame", {
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(pct, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = track,
    })
    addCorner(knob, Flow.Radius.full)
    addStroke(knob, Flow.Theme.accent, 2)

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
    track.MouseButton1Down:Connect(function(x) dragging = true; updateFromX(x) end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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
        for i, b in ipairs(btns) do
            b.TextColor3 = (i <= val) and Flow.Theme.warning or Flow.Theme.muted
        end
    end
    for i = 1, maxStars do
        local b = create("TextButton", {
            Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1,
            Font = Flow.Fonts.bold,
            TextSize = 18,
            Text = "★",
            AutoButtonColor = false,
            Parent = row,
        })
        b.MouseButton1Click:Connect(function()
            val = i
            render()
            if opts.Callback then opts.Callback(val) end
        end)
        table.insert(btns, b)
    end
    render()
    return { Instance = row, Get = function() return val end }
end

function ContainerMethods:Input(opts)
    opts = opts or {}
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, opts.Label and 58 or 36),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    addList(holder, Enum.FillDirection.Vertical, 4)
    if opts.Label then
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Font = Flow.Fonts.sans,
            TextSize = 12,
            TextColor3 = Flow.Theme.foreground,
            Text = opts.Label,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })
    end
    local boxFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Flow.Theme.surface,
        Parent = holder,
    })
    addCorner(boxFrame, Flow.Radius.md)
    local st = addStroke(boxFrame, Flow.Theme.border, 1)
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
    tb.Focused:Connect(function() tween(st, { Color = Flow.Theme.accent }, 0.14) end)
    tb.FocusLost:Connect(function(enter)
        tween(st, { Color = Flow.Theme.border }, 0.14)
        if opts.Callback then opts.Callback(tb.Text, enter) end
    end)
    return { Instance = holder, TextBox = tb, Get = function() return tb.Text end, Set = function(_, v) tb.Text = tostring(v) end }
end

function ContainerMethods:TextField(opts) return self:Input(opts) end
function ContainerMethods:SearchField(opts)
    opts = opts or {}
    opts.Placeholder = opts.Placeholder or "Search..."
    return self:Input(opts)
end

function ContainerMethods:InputGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Flow.Theme.surface, Parent = self._frame })
    addCorner(row, Flow.Radius.md)
    addStroke(row, Flow.Theme.border, 1)
    addPadding(row, 0, 10, 0, 10)
    addList(row, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 34),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.mono,
        TextSize = 12,
        TextColor3 = Flow.Theme.muted,
        Text = opts.Prefix or "https://",
        Parent = row,
    })
    local tb = create("TextBox", {
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        PlaceholderText = opts.Placeholder or "heroui.com",
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    return { Instance = row, TextBox = tb }
end

function ContainerMethods:TextArea(opts)
    opts = opts or {}
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, opts.Height or 84),
        BackgroundColor3 = Flow.Theme.surface,
        Parent = self._frame,
    })
    addCorner(box, Flow.Radius.md)
    addStroke(box, Flow.Theme.border, 1)
    addPadding(box, 8, 10, 8, 10)
    local tb = create("TextBox", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        PlaceholderColor3 = Flow.Theme.muted,
        PlaceholderText = opts.Placeholder or "Write a message...",
        Text = opts.Default or "",
        MultiLine = true,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ClearTextOnFocus = false,
        Parent = box,
    })
    tb.FocusLost:Connect(function() if opts.Callback then opts.Callback(tb.Text) end end)
    return { Instance = box, TextBox = tb, Get = function() return tb.Text end }
end

function ContainerMethods:NumberField(opts)
    opts = opts or {}
    local val = opts.Default or 0
    local step = opts.Step or 1
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Flow.Theme.surface, Parent = self._frame })
    addCorner(row, Flow.Radius.md)
    addStroke(row, Flow.Theme.border, 1)
    addPadding(row, 0, 8, 0, 10)
    local lbl = create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = opts.Label or "Number",
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local ctrl = create("Frame", { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Parent = row })
    addList(ctrl, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local valTxt = create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(32, 24),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.mono,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = tostring(val),
        Parent = ctrl,
    })
    local minus = create("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = Flow.Theme.defaultSoft,
        Font = Flow.Fonts.bold,
        TextSize = 14,
        TextColor3 = Flow.Theme.foreground,
        Text = "-",
        AutoButtonColor = false,
        Parent = ctrl,
    })
    addCorner(minus, Flow.Radius.sm)
    local plus = create("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = Flow.Theme.defaultSoft,
        Font = Flow.Fonts.bold,
        TextSize = 14,
        TextColor3 = Flow.Theme.foreground,
        Text = "+",
        AutoButtonColor = false,
        Parent = ctrl,
    })
    addCorner(plus, Flow.Radius.sm)
    minus.MouseButton1Click:Connect(function()
        val = val - step
        valTxt.Text = tostring(val)
        if opts.Callback then opts.Callback(val) end
    end)
    plus.MouseButton1Click:Connect(function()
        val = val + step
        valTxt.Text = tostring(val)
        if opts.Callback then opts.Callback(val) end
    end)
    return { Instance = row, Label = lbl, Get = function() return val end }
end

function ContainerMethods:NumberStepper(opts) return self:NumberField(opts) end
function ContainerMethods:NumberValue(opts)
    opts = opts or {}
    return self:Typography({ Text = tostring(opts.Value or "1,024"), Variant = "h2", Mono = true })
end

function ContainerMethods:InputOtp(opts)
    opts = opts or {}
    local len = opts.Length or 4
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 8)
    local boxes = {}
    for i = 1, len do
        local tb = create("TextBox", {
            Size = UDim2.fromOffset(38, 40),
            BackgroundColor3 = Flow.Theme.surface,
            Font = Flow.Fonts.mono,
            TextSize = 16,
            TextColor3 = Flow.Theme.foreground,
            Text = "",
            PlaceholderText = "•",
            Parent = row,
        })
        addCorner(tb, Flow.Radius.md)
        addStroke(tb, Flow.Theme.border, 1)
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            if #tb.Text > 1 then tb.Text = string.sub(tb.Text, 1, 1) end
            if #tb.Text == 1 and boxes[i + 1] then boxes[i + 1]:CaptureFocus() end
        end)
        boxes[i] = tb
    end
    return { Instance = row, Get = function()
        local s = ""
        for _, b in ipairs(boxes) do s = s .. b.Text end
        return s
    end }
end

function ContainerMethods:Fieldset(opts)
    opts = opts or {}
    return self:Card({ Title = opts.Legend or "Fieldset", Description = opts.Description })
end

function ContainerMethods:Form(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Form" })
    if opts.OnSubmit then
        card:Button({ Text = opts.SubmitText or "Submit", Callback = opts.OnSubmit })
    end
    return card
end

function ContainerMethods:DropZone(opts)
    opts = opts or {}
    local dz = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = Flow.Theme.surface,
        Font = Flow.Fonts.regular,
        TextSize = 12,
        TextColor3 = Flow.Theme.muted,
        Text = opts.Text or "Click or drop files here",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(dz, Flow.Radius.lg)
    addStroke(dz, Flow.Theme.border, 1.5)
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
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Flow.Theme.surfaceSecondary,
        Parent = self._frame,
    })
    addCorner(box, Flow.Radius.md)
    addStroke(box, Flow.Theme.border, 1)
    addPadding(box, 10, 12, 10, 12)
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.mono,
        TextSize = 12,
        TextColor3 = Flow.Theme.accentSoftForeground,
        Text = opts.Code or "print('Hello FlowUI')",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = box,
    })
    return { Instance = box, SetCode = function(_, c) lbl.Text = tostring(c) end }
end

function ContainerMethods:Markdown(opts)
    opts = opts or {}
    return self:Typography({ Text = opts.Text or "# Markdown Heading\nRendered cleanly in FlowUI.", Variant = "body" })
end

--============================================================================--
-- SECTION 3: SELECTION, MENUS, NAVIGATION & DISCLOSURE
--============================================================================--

function ContainerMethods:Select(opts)
    opts = opts or {}
    local items = opts.Items or { "Option 1", "Option 2", "Option 3" }
    local selected = opts.Default or items[1]
    local open = false

    local wrapper = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    addList(wrapper, Enum.FillDirection.Vertical, 4)

    local trigger = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Flow.Theme.surface,
        Font = Flow.Fonts.regular,
        TextSize = 13,
        TextColor3 = Flow.Theme.foreground,
        Text = "  " .. (opts.Label and (opts.Label .. ": ") or "") .. tostring(selected) .. "  ▾",
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = wrapper,
    })
    addCorner(trigger, Flow.Radius.md)
    addStroke(trigger, Flow.Theme.border, 1)

    local menu = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Flow.Theme.overlay,
        Visible = false,
        Parent = wrapper,
    })
    addCorner(menu, Flow.Radius.md)
    addStroke(menu, Flow.Theme.border, 1)
    addPadding(menu, 4)
    addList(menu, Enum.FillDirection.Vertical, 2)

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
            Parent = menu,
        })
        addCorner(opt, Flow.Radius.sm)
        opt.MouseEnter:Connect(function() opt.BackgroundTransparency = 0 end)
        opt.MouseLeave:Connect(function() opt.BackgroundTransparency = 1 end)
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
            BackgroundColor3 = Flow.Theme.surfaceSecondary,
            BackgroundTransparency = 1,
            Font = Flow.Fonts.regular,
            TextSize = 13,
            TextColor3 = Flow.Theme.foreground,
            Text = "  " .. tostring(item),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = card._frame,
        })
        addCorner(b, Flow.Radius.sm)
        b.MouseButton1Click:Connect(function()
            selected = item
            if opts.Callback then opts.Callback(item) end
        end)
    end
    return { Card = card, Get = function() return selected end }
end

function ContainerMethods:ListView(opts) return self:ListBox(opts) end

function ContainerMethods:ContextMenu(opts)
    opts = opts or {}
    local target = self:Surface({ Padding = 12 })
    target:Typography({ Text = opts.Text or "Right-click here for ContextMenu", Variant = "caption" })
    local items = opts.Items or { "Copy", "Paste", "Delete" }

    target._frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Flow:_ensureRoot()
            for _, c in ipairs(Flow._overlayLayer:GetChildren()) do
                if c.Name == "FlowContextMenu" then c:Destroy() end
            end
            local menu = create("Frame", {
                Name = "FlowContextMenu",
                Size = UDim2.fromOffset(160, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.fromOffset(input.Position.X, input.Position.Y),
                BackgroundColor3 = Flow.Theme.overlay,
                ZIndex = 250,
                Parent = Flow._overlayLayer,
            })
            addCorner(menu, Flow.Radius.md)
            addStroke(menu, Flow.Theme.border, 1)
            addPadding(menu, 4)
            addList(menu, Enum.FillDirection.Vertical, 2)
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
                b.MouseButton1Click:Connect(function()
                    menu:Destroy()
                    if opts.Callback then opts.Callback(item) end
                end)
            end
        end
    end)
    return target
end

function Flow:Command(opts)
    opts = opts or {}
    self:_ensureRoot()
    local overlay = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        ZIndex = 260,
        Parent = self._overlayLayer,
    })
    local box = create("Frame", {
        Size = UDim2.fromOffset(420, 260),
        Position = UDim2.new(0.5, -210, 0.35, -130),
        BackgroundColor3 = self.Theme.overlay,
        ZIndex = 261,
        Parent = overlay,
    })
    addCorner(box, self.Radius.lg)
    addStroke(box, self.Theme.border, 1)
    addPadding(box, 10)
    addList(box, Enum.FillDirection.Vertical, 8)
    local w = wrapContainer(box)
    w:Input({ Placeholder = opts.Placeholder or "Type a command...", Callback = function() end })
    for _, item in ipairs(opts.Items or { "Toggle Theme", "Reload Config", "Close" }) do
        w:Button({ Text = item, Variant = "ghost", Size = UDim2.new(1, 0, 0, 30), Callback = function()
            overlay:Destroy()
            if opts.Callback then opts.Callback(item) end
        end })
    end
    w:Button({ Text = "Close Palette", Color = "danger", Variant = "soft", Size = UDim2.new(1, 0, 0, 30), Callback = function()
        overlay:Destroy()
    end })
    return { Overlay = overlay }
end
function ContainerMethods:Command(opts) return Flow:Command(opts) end

function ContainerMethods:Tabs(opts)
    opts = opts or {}
    local items = opts.Items or { "Tab 1", "Tab 2", "Tab 3" }
    local active = opts.Default or items[1]
    local bar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Flow.Theme.surfaceSecondary,
        Parent = self._frame,
    })
    addCorner(bar, Flow.Radius.md)
    addPadding(bar, 4)
    addList(bar, Enum.FillDirection.Horizontal, 4)
    local btns = {}
    local function render()
        for k, b in pairs(btns) do
            local isAct = (k == active)
            tween(b, {
                BackgroundColor3 = isAct and Flow.Theme.surface or Flow.Theme.surfaceSecondary,
                BackgroundTransparency = isAct and 0 or 1,
                TextColor3 = isAct and Flow.Theme.foreground or Flow.Theme.muted,
            }, 0.14)
        end
    end
    for _, item in ipairs(items) do
        local b = create("TextButton", {
            Size = UDim2.new(1 / #items, -3, 1, 0),
            BackgroundColor3 = Flow.Theme.surface,
            Font = Flow.Fonts.sans,
            TextSize = 12,
            TextColor3 = Flow.Theme.muted,
            Text = item,
            AutoButtonColor = false,
            Parent = bar,
        })
        addCorner(b, Flow.Radius.sm)
        btns[item] = b
        b.MouseButton1Click:Connect(function()
            active = item
            render()
            if opts.Callback then opts.Callback(item) end
        end)
    end
    render()
    return { Instance = bar, Get = function() return active end }
end

function ContainerMethods:Segment(opts) return self:Tabs(opts) end

function ContainerMethods:Breadcrumbs(opts)
    opts = opts or {}
    local items = opts.Items or { "Home", "Library", "Components" }
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    for i, item in ipairs(items) do
        create("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Font = (i == #items) and Flow.Fonts.bold or Flow.Fonts.regular,
            TextSize = 12,
            TextColor3 = (i == #items) and Flow.Theme.foreground or Flow.Theme.muted,
            Text = item,
            Parent = row,
        })
        if i < #items then
            create("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Font = Flow.Fonts.regular,
                TextSize = 12,
                TextColor3 = Flow.Theme.muted,
                Text = "/",
                Parent = row,
            })
        end
    end
    return { Instance = row }
end

function ContainerMethods:Pagination(opts)
    opts = opts or {}
    local total = opts.Total or 5
    local page = opts.Default or 1
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 4)
    local btns = {}
    local function render()
        for i, b in ipairs(btns) do
            b.BackgroundColor3 = (i == page) and Flow.Theme.accent or Flow.Theme.defaultSoft
            b.TextColor3 = (i == page) and Flow.Theme.accentForeground or Flow.Theme.foreground
        end
    end
    for i = 1, total do
        local b = create("TextButton", {
            Size = UDim2.fromOffset(28, 28),
            Font = Flow.Fonts.sans,
            TextSize = 12,
            Text = tostring(i),
            AutoButtonColor = false,
            Parent = row,
        })
        addCorner(b, Flow.Radius.sm)
        btns[i] = b
        b.MouseButton1Click:Connect(function()
            page = i
            render()
            if opts.Callback then opts.Callback(page) end
        end)
    end
    render()
    return { Instance = row, Get = function() return page end }
end

function ContainerMethods:Stepper(opts)
    opts = opts or {}
    local steps = opts.Steps or { "Step 1", "Step 2", "Step 3" }
    local current = opts.Current or 1
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    for i, s in ipairs(steps) do
        local done = i <= current
        local chip = create("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 26),
            BackgroundColor3 = done and Flow.Theme.accentSoft or Flow.Theme.surfaceSecondary,
            Font = Flow.Fonts.sans,
            TextSize = 11,
            TextColor3 = done and Flow.Theme.accentSoftForeground or Flow.Theme.muted,
            Text = tostring(i) .. ". " .. s,
            Parent = row,
        })
        addCorner(chip, Flow.Radius.full)
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
    local body = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = open,
        Parent = card._frame,
    })
    addList(body, Enum.FillDirection.Vertical, 6)
    header.MouseButton1Click:Connect(function()
        open = not open
        body.Visible = open
        header.Text = (open and "▾ " or "▸ ") .. (opts.Title or "Disclosure")
    end)
    local bw = wrapContainer(body)
    if opts.Content then
        bw:Typography({ Text = opts.Content, Variant = "caption" })
    end
    return bw
end

function ContainerMethods:Accordion(opts) return self:Disclosure(opts) end
function ContainerMethods:DisclosureGroup(opts)
    opts = opts or {}
    local box = self:Surface({ Padding = 8, Gap = 6 })
    for _, item in ipairs(opts.Items or {
        { Title = "What is FlowUI?", Content = "A HeroUI-inspired Roblox UI framework." },
        { Title = "Does it support themes?", Content = "Yes, Dark, Light, and custom tokens." },
    }) do
        box:Disclosure(item)
    end
    return box
end

function ContainerMethods:TagGroup(opts)
    opts = opts or {}
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = self._frame })
    addList(row, Enum.FillDirection.Horizontal, 6)
    local w = wrapContainer(row)
    for _, t in ipairs(opts.Tags or { "React", "HeroUI", "Luau" }) do
        w:Chip({ Text = t, Variant = "soft", Color = opts.Color or "default" })
    end
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
    local bg, fg, border = getColorPair(opts.Color or "accent", "soft")
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = bg,
        Parent = self._frame,
    })
    addCorner(box, Flow.Radius.md)
    addStroke(box, border, 1)
    addPadding(box, 10, 14, 10, 14)
    addList(box, Enum.FillDirection.Vertical, 2)
    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 13,
        TextColor3 = fg,
        Text = opts.Title or "Notice",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = box,
    })
    if opts.Description then
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = Flow.Fonts.regular,
            TextSize = 12,
            TextColor3 = Flow.Theme.foreground,
            Text = opts.Description,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = box,
        })
    end
    return { Instance = box }
end

function Flow:Toast(opts)
    opts = opts or {}
    self:_ensureRoot()
    local bg, fg, border = getColorPair(opts.Color or "default", "soft")
    local toast = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.overlay,
        ZIndex = 310,
        Parent = self._toastLayer,
    })
    addCorner(toast, self.Radius.lg)
    addStroke(toast, border, 1)
    addPadding(toast, 10, 14, 10, 14)
    addList(toast, Enum.FillDirection.Vertical, 3)

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = self.Fonts.bold,
        TextSize = 13,
        TextColor3 = fg,
        Text = opts.Title or "Notification",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 311,
        Parent = toast,
    })
    if opts.Description then
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = self.Fonts.regular,
            TextSize = 12,
            TextColor3 = self.Theme.muted,
            Text = opts.Description,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 311,
            Parent = toast,
        })
    end
    task.delay(opts.Duration or 3.5, function()
        if toast and toast.Parent then
            toast:Destroy()
        end
    end)
    return { Instance = toast }
end
function ContainerMethods:Toast(opts) return Flow:Toast(opts) end

function Flow:Modal(opts)
    opts = opts or {}
    self:_ensureRoot()
    local backdrop = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 240,
        Parent = self._overlayLayer,
    })
    local card = create("Frame", {
        Size = opts.Size or UDim2.fromOffset(380, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, -((opts.Size and opts.Size.X.Offset or 380) / 2), 0.5, -110),
        BackgroundColor3 = self.Theme.overlay,
        ZIndex = 241,
        Parent = backdrop,
    })
    addCorner(card, self.Radius.xl)
    addStroke(card, self.Theme.border, 1)
    addPadding(card, 16)
    addList(card, Enum.FillDirection.Vertical, 10)

    local w = wrapContainer(card)
    w:Typography({ Text = opts.Title or "Modal Dialog", Variant = "h3" })
    if opts.Description then
        w:Description({ Text = opts.Description })
    end
    local actions = create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = card })
    addList(actions, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local aw = wrapContainer(actions)
    aw:Button({ Text = opts.CancelText or "Cancel", Variant = "soft", Color = "default", Size = UDim2.fromOffset(90, 32), Callback = function()
        backdrop:Destroy()
        if opts.OnCancel then opts.OnCancel() end
    end })
    aw:Button({ Text = opts.ConfirmText or "Confirm", Color = opts.Color or "accent", Size = UDim2.fromOffset(100, 32), Callback = function()
        backdrop:Destroy()
        if opts.OnConfirm then opts.OnConfirm() end
    end })
    return { Backdrop = backdrop, Body = w }
end
function ContainerMethods:Modal(opts) return Flow:Modal(opts) end

function Flow:AlertDialog(opts)
    opts = opts or {}
    opts.Color = opts.Color or "danger"
    opts.ConfirmText = opts.ConfirmText or "Delete"
    return self:Modal(opts)
end
function ContainerMethods:AlertDialog(opts) return Flow:AlertDialog(opts) end

function Flow:Drawer(opts)
    opts = opts or {}
    self:_ensureRoot()
    local backdrop = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 240,
        Parent = self._overlayLayer,
    })
    local panel = create("Frame", {
        Size = UDim2.new(0, opts.Width or 300, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = self.Theme.overlay,
        ZIndex = 241,
        Parent = backdrop,
    })
    addStroke(panel, self.Theme.border, 1)
    addPadding(panel, 16)
    addList(panel, Enum.FillDirection.Vertical, 10)
    tween(panel, { Position = UDim2.new(1, -(opts.Width or 300), 0, 0) }, 0.2)
    local w = wrapContainer(panel)
    w:Typography({ Text = opts.Title or "Drawer", Variant = "h3" })
    if opts.Description then w:Description({ Text = opts.Description }) end
    w:Button({ Text = "Close Drawer", Variant = "soft", Color = "default", Callback = function() backdrop:Destroy() end })
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
    local pop = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Flow.Theme.overlay,
        Visible = false,
        Parent = box,
    })
    addCorner(pop, Flow.Radius.md)
    addStroke(pop, Flow.Theme.border, 1)
    addPadding(pop, 10)
    addList(pop, Enum.FillDirection.Vertical, 6)
    w:Button({ Text = opts.TriggerText or "Toggle Popover", Variant = "soft", Color = "default", Callback = function()
        open = not open
        pop.Visible = open
    end })
    local pw = wrapContainer(pop)
    if opts.Content then pw:Typography({ Text = opts.Content, Variant = "small" }) end
    return pw
end

function ContainerMethods:HoverCard(opts) return self:Popover(opts) end
function ContainerMethods:Tooltip(opts)
    opts = opts or {}
    local lbl = self:Chip({ Text = opts.Text or "Hover me for Tooltip", Variant = "outline" })
    Flow:_attachTooltip(lbl.Instance, opts.Tip or "HeroUI Tooltip")
    return lbl
end

function ContainerMethods:ProgressBar(opts)
    opts = opts or {}
    local val = math.clamp(opts.Value or 60, 0, 100)
    local box = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = self._frame })
    addList(box, Enum.FillDirection.Vertical, 4)
    if opts.Label then
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Font = Flow.Fonts.regular,
            TextSize = 12,
            TextColor3 = Flow.Theme.foreground,
            Text = opts.Label .. " (" .. tostring(val) .. "%)",
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = box,
        })
    end
    local track = create("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Flow.Theme.surfaceSecondary, Parent = box })
    addCorner(track, Flow.Radius.full)
    local fill = create("Frame", {
        Size = UDim2.new(val / 100, 0, 1, 0),
        BackgroundColor3 = Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent,
        Parent = track,
    })
    addCorner(fill, Flow.Radius.full)
    return { Instance = box, Set = function(_, v)
        val = math.clamp(v, 0, 100)
        tween(fill, { Size = UDim2.new(val / 100, 0, 1, 0) }, 0.2)
    end }
end

function ContainerMethods:Meter(opts) return self:ProgressBar(opts) end
function ContainerMethods:ProgressCircle(opts)
    opts = opts or {}
    local val = math.clamp(opts.Value or 75, 0, 100)
    local sz = opts.Size or 48
    local ring = create("Frame", { Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = Flow.Theme.surfaceSecondary, Parent = self._frame })
    addCorner(ring, Flow.Radius.full)
    addStroke(ring, Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent, 4)
    create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 12,
        TextColor3 = Flow.Theme.foreground,
        Text = tostring(val) .. "%",
        Parent = ring,
    })
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
            BackgroundColor3 = (d == sel) and Flow.Theme.accent or Flow.Theme.surfaceSecondary,
            Font = Flow.Fonts.sans,
            TextSize = 11,
            TextColor3 = (d == sel) and Flow.Theme.accentForeground or Flow.Theme.foreground,
            Text = tostring(d),
            AutoButtonColor = false,
            Parent = grid,
        })
        addCorner(b, Flow.Radius.sm)
        b.MouseButton1Click:Connect(function()
            sel = d
            if opts.Callback then opts.Callback(d) end
        end)
    end
    return card
end

function ContainerMethods:RangeCalendar(opts) return self:Calendar(opts) end
function ContainerMethods:DateField(opts)
    opts = opts or {}
    opts.Placeholder = opts.Placeholder or "YYYY-MM-DD"
    opts.Label = opts.Label or "Date"
    return self:Input(opts)
end
function ContainerMethods:DatePicker(opts) return self:DateField(opts) end
function ContainerMethods:DateRangePicker(opts)
    opts = opts or {}
    opts.Placeholder = "2026-11-01 -> 2026-11-30"
    opts.Label = opts.Label or "Date Range"
    return self:Input(opts)
end
function ContainerMethods:TimeField(opts)
    opts = opts or {}
    opts.Placeholder = "14:30"
    opts.Label = opts.Label or "Time"
    return self:Input(opts)
end

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
    for _, item in ipairs(opts.Items or { "Initialized FlowUI", "Added 142 HeroUI Components", "Ready for Executor" }) do
        card:Typography({ Text = "●  " .. item, Variant = "small" })
    end
    return card
end

function ContainerMethods:ColorSwatch(opts)
    opts = opts or {}
    local sw = create("Frame", {
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = opts.Color or Flow.Theme.accent,
        Parent = self._frame,
    })
    addCorner(sw, Flow.Radius.sm)
    addStroke(sw, Flow.Theme.border, 1)
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
        local b = create("TextButton", {
            Size = UDim2.fromOffset(24, 24),
            BackgroundColor3 = c,
            Text = "",
            AutoButtonColor = false,
            Parent = row,
        })
        addCorner(b, Flow.Radius.full)
        addStroke(b, Flow.Theme.border, 1)
        b.MouseButton1Click:Connect(function()
            if opts.Callback then opts.Callback(c) end
        end)
    end
    return { Instance = row }
end

function ContainerMethods:ColorArea(opts)
    opts = opts or {}
    local area = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 90),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    addCorner(area, Flow.Radius.md)
    create("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(0, 111, 238)),
        Parent = area,
    })
    area.MouseButton1Click:Connect(function()
        if opts.Callback then opts.Callback(Flow.Theme.accent) end
    end)
    return { Instance = area }
end

function ContainerMethods:ColorSlider(opts)
    opts = opts or {}
    return self:Slider({ Label = opts.Label or "Hue", Min = 0, Max = 360, Default = 210, Callback = function(h)
        if opts.Callback then opts.Callback(Color3.fromHSV(h / 360, 0.85, 0.95)) end
    end })
end

function ContainerMethods:ColorField(opts)
    opts = opts or {}
    opts.Label = opts.Label or "Hex Color"
    opts.Placeholder = "#006FEE"
    return self:Input(opts)
end

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
        local b = create("TextButton", {
            Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = Flow.Theme.surfaceSecondary,
            Text = em,
            TextSize = 15,
            AutoButtonColor = false,
            Parent = row,
        })
        addCorner(b, Flow.Radius.sm)
        b.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback(em) end end)
    end
    return { Instance = row }
end

function ContainerMethods:EmojiReactionButton(opts)
    opts = opts or {}
    local count = opts.Count or 1
    local btn = self:Button({
        Text = (opts.Emoji or "🔥") .. " " .. tostring(count),
        Variant = "soft",
        Color = "default",
        Size = UDim2.fromOffset(68, 28),
    })
    btn.Instance.MouseButton1Click:Connect(function()
        count = count + 1
        btn:SetText((opts.Emoji or "🔥") .. " " .. tostring(count))
    end)
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
        local r = create("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = isHeader and Flow.Theme.surfaceSecondary or Flow.Theme.surface,
            Parent = card._frame,
        })
        addCorner(r, Flow.Radius.sm)
        addList(r, Enum.FillDirection.Horizontal, 0)
        for _, cell in ipairs(cells) do
            create("TextLabel", {
                Size = UDim2.new(1 / #cells, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = isHeader and Flow.Fonts.bold or Flow.Fonts.regular,
                TextSize = 12,
                TextColor3 = isHeader and Flow.Theme.muted or Flow.Theme.foreground,
                Text = "  " .. tostring(cell),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = r,
            })
        end
    end

    makeRow(cols, true)
    for _, row in ipairs(rows) do
        makeRow(row, false)
    end
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
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    create("UIGridLayout", {
        CellSize = UDim2.new(0.48, 0, 0, 108),
        CellPadding = UDim2.fromOffset(10, 10),
        Parent = row,
    })
    local w = wrapContainer(row)
    for _, k in ipairs(opts.Items or {
        { Title = "Active Users", Value = "12,480", Delta = "+14.2%", Direction = "up" },
        { Title = "Latency", Value = "24ms", Delta = "-4.1%", Direction = "up" },
    }) do
        w:Kpi(k)
    end
    return w
end

function ContainerMethods:Kanban(opts)
    opts = opts or {}
    local cols = opts.Columns or {
        { Title = "To Do", Cards = { "Design tokens", "Executor test" } },
        { Title = "In Progress", Cards = { "HeroUI parity" } },
        { Title = "Done", Cards = { "Core framework" } },
    }
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self._frame,
    })
    addList(row, Enum.FillDirection.Horizontal, 10)
    for _, col in ipairs(cols) do
        local c = create("Frame", {
            Size = UDim2.new(1 / #cols, -7, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Flow.Theme.surface,
            Parent = row,
        })
        addCorner(c, Flow.Radius.md)
        addStroke(c, Flow.Theme.border, 1)
        addPadding(c, 8)
        addList(c, Enum.FillDirection.Vertical, 6)
        local cw = wrapContainer(c)
        cw:Label({ Text = col.Title })
        for _, cardTitle in ipairs(col.Cards or {}) do
            cw:Chip({ Text = cardTitle, Variant = "soft", Color = "default" })
        end
    end
    return { Instance = row }
end

function ContainerMethods:Carousel(opts)
    opts = opts or {}
    local slides = opts.Slides or { "Slide 1: Welcome to FlowUI", "Slide 2: 142 HeroUI Components", "Slide 3: Dark & Light Themes" }
    local idx = 1
    local card = self:Card({ Title = opts.Title or "Carousel" })
    local lbl = card:Typography({ Text = slides[idx], Variant = "h4" })
    local nav = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = card._frame })
    addList(nav, Enum.FillDirection.Horizontal, 8)
    local nw = wrapContainer(nav)
    nw:Button({ Text = "Prev", Variant = "soft", Color = "default", Size = UDim2.fromOffset(70, 28), Callback = function()
        idx = ((idx - 2) % #slides) + 1
        lbl:SetText(slides[idx])
    end })
    nw:Button({ Text = "Next", Variant = "soft", Color = "accent", Size = UDim2.fromOffset(70, 28), Callback = function()
        idx = (idx % #slides) + 1
        lbl:SetText(slides[idx])
    end })
    return card
end

function ContainerMethods:Map(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Map Viewport", Description = opts.Location or "San Francisco, CA (37.7749, -122.4194)" })
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 90),
        BackgroundColor3 = Flow.Theme.accentSoft,
        Parent = card._frame,
    })
    addCorner(box, Flow.Radius.md)
    create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Flow.Fonts.bold,
        TextSize = 16,
        TextColor3 = Flow.Theme.accentSoftForeground,
        Text = "📍 " .. (opts.Location or "Map Marker"),
        Parent = box,
    })
    return card
end

--// Charts (BarChart, AreaChart, LineChart, PieChart, RadarChart, RadialChart, ComposedChart, ChartTooltip)
function ContainerMethods:BarChart(opts)
    opts = opts or {}
    local data = opts.Data or { 35, 65, 48, 90, 72, 55, 84 }
    local card = self:Card({ Title = opts.Title or "Bar Chart" })
    local plot = create("Frame", {
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Flow.Theme.surfaceSecondary,
        Parent = card._frame,
    })
    addCorner(plot, Flow.Radius.md)
    addPadding(plot, 10)
    addList(plot, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)
    local maxV = 1
    for _, v in ipairs(data) do if v > maxV then maxV = v end end
    for _, v in ipairs(data) do
        local bar = create("Frame", {
            Size = UDim2.new(1 / #data, -8, v / maxV, 0),
            BackgroundColor3 = Flow.Theme[opts.Color or "accent"] or Flow.Theme.accent,
            Parent = plot,
        })
        addCorner(bar, Flow.Radius.sm)
        Flow:_attachTooltip(bar, "Value: " .. tostring(v))
    end
    return card
end

function ContainerMethods:AreaChart(opts)
    opts = opts or {}
    opts.Title = opts.Title or "Area Chart"
    opts.Color = opts.Color or "success"
    return self:BarChart(opts)
end

function ContainerMethods:LineChart(opts)
    opts = opts or {}
    opts.Title = opts.Title or "Line Chart"
    return self:BarChart(opts)
end

function ContainerMethods:ComposedChart(opts)
    opts = opts or {}
    opts.Title = opts.Title or "Composed Chart"
    return self:BarChart(opts)
end

function ContainerMethods:PieChart(opts)
    opts = opts or {}
    local card = self:Card({ Title = opts.Title or "Pie Chart" })
    card:ProgressCircle({ Value = opts.Value or 68, Size = 64, Color = "accent" })
    return card
end

function ContainerMethods:RadialChart(opts)
    opts = opts or {}
    opts.Title = opts.Title or "Radial Chart"
    return self:PieChart(opts)
end

function ContainerMethods:RadarChart(opts)
    opts = opts or {}
    opts.Title = opts.Title or "Radar Chart"
    return self:BarChart(opts)
end

function ContainerMethods:ChartTooltip(opts)
    opts = opts or {}
    return self:Chip({ Text = opts.Text or "Jan: 420 pts", Color = "accent", Variant = "soft" })
end

--// AI & Chat Components
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

function ContainerMethods:ChainOfThought(opts)
    opts = opts or {}
    return self:Disclosure({ Title = opts.Title or "Chain of Thought", Content = opts.Content or "1. Parsed request\n2. Built theme tokens\n3. Rendered UI", DefaultOpen = false })
end

function ContainerMethods:Reasoning(opts)
    opts = opts or {}
    opts.Title = opts.Title or "Reasoning"
    return self:ChainOfThought(opts)
end

function ContainerMethods:ChatAttachment(opts)
    opts = opts or {}
    return self:Chip({ Text = "📎 " .. (opts.Name or "attachment.lua"), Variant = "outline" })
end

function ContainerMethods:ChatLoader(opts)
    opts = opts or {}
    return self:TextShimmer({ Text = opts.Text or "Assistant is typing..." })
end

function ContainerMethods:ChatSource(opts)
    opts = opts or {}
    return self:Link({ Text = "🔗 Source: " .. (opts.Title or "heroui.com/docs") })
end

function ContainerMethods:ChatTool(opts)
    opts = opts or {}
    return self:Chip({ Text = "⚙ Tool: " .. (opts.Name or "read_file"), Color = "warning", Variant = "soft" })
end

function ContainerMethods:ChatMessageActions(opts)
    opts = opts or {}
    return self:Toolbar({ Actions = opts.Actions or { "Copy", "Retry", "👍", "👎" }, Callback = opts.Callback })
end

function ContainerMethods:ChatMessage(opts)
    opts = opts or {}
    local isUser = (opts.Role == "user")
    local box = self:Surface({
        Background = isUser and "accentSoft" or "surface",
        Padding = 10,
        Gap = 4,
    })
    box:Label({ Text = isUser and "You" or (opts.Sender or "Assistant"), Size = 11, Color = isUser and "accentSoftForeground" or "muted" })
    box:Typography({ Text = opts.Text or "Hello! How can I help you today?", Variant = "body" })
    return box
end

function ContainerMethods:ChatConversation(opts)
    opts = opts or {}
    local box = self:ScrollShadow({ Height = opts.Height or 160 })
    for _, msg in ipairs(opts.Messages or {
        { Role = "user", Text = "Create a HeroUI Roblox library." },
        { Role = "assistant", Text = "Done! All 142 HeroUI components are ready in Flow.lua." },
    }) do
        box:ChatMessage(msg)
    end
    return box
end

function ContainerMethods:ChatListView(opts)
    opts = opts or {}
    return self:ListBox({ Title = opts.Title or "Conversations", Items = opts.Items or { "UI Architecture", "Theme Tokens", "Executor Script" } })
end

function ContainerMethods:ModelSelector(opts)
    opts = opts or {}
    return self:Select({ Label = "Model", Items = opts.Models or { "Gemini 4", "Claude Sonnet", "GPT-5" }, Callback = opts.Callback })
end

function ContainerMethods:PromptSuggestion(opts)
    opts = opts or {}
    return self:Chip({ Text = "✨ " .. (opts.Text or "Generate Roblox UI"), Color = "accent", Variant = "soft" })
end

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
