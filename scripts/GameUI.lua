local UI = require("urhox-libs/UI")
local ImageCache = require("urhox-libs/UI/Core/ImageCache")
local Widget = require("urhox-libs/UI/Core/Widget")
local GearRenderer = require("GearRenderer")

local GameUI = {}

local landscapeLeftRailCollapsed_ = true
local landscapeRightRailCollapsed_ = true
local COIN_ICON_PATH = "image/ui_coin_brass_comic_20260807004421.png"
local ESSENCE_ICON_PATH = "image/ui_essence_core_comic_20260807004430.png"
local TORQUE_ICON_PATH = "image/ui_torque_bolt_comic_20260807004422.png"
local HOME_HUD_ICON_PATH =
    "image/gear_workshop_home_hud_icon_20260817122607.png"
local ASCENSION_ICON_PATH = "image/hud_b_extracted/permanent.png"
local LOCKED_QUESTION_ICON_PATH =
    "image/locked_question_gear_comic_20260817094517.png"
local HUD_B_ICON_PATHS = {
    shaft = "image/hud_b_extracted/shaft.png",
    income = "image/hud_b_extracted/income.png",
    click = "image/hud_b_extracted/click.png",
    permanent = ASCENSION_ICON_PATH,
    modify = "image/hud_b_extracted/modify.png",
    small = "image/gear_small_comic_exact.png",
    medium = "image/gear_medium_comic_exact.png",
    large = "image/gear_large_comic_exact.png",
    compound = "image/gear_compound_comic_exact.png",
    coin = "image/gear_coin_large_comic_20260811093509.png",
}
local SIDE_RAIL_IMAGE_PATHS = {
    leftPanel = "image/ui_blueprint_clean/panel_left.png",
    rightPanel = "image/ui_blueprint_clean/panel_right.png",
    shopCard = "image/ui_blueprint_clean/card_shop.png",
    shopCardSmall = "image/ui_blueprint_clean/card_shop.png",
    shopCardMedium = "image/ui_blueprint_clean/card_shop.png",
    shopCardLarge = "image/ui_blueprint_clean/card_shop.png",
    shopCardCompound = "image/ui_blueprint_clean/card_shop.png",
    upgradeCard = "image/ui_blueprint_clean/card_upgrade.png",
    leftHandle = "image/ui_blueprint_clean/handle_left.png",
    rightHandle = "image/ui_blueprint_clean/handle_right.png",
    topHud = "image/ui_blueprint_clean/top_hud_frame.png",
}
local imageIconHandlesByContext_ = {}

local DIAL_CENTER_X_RATIO = 0.50
local DIAL_CENTER_Y_RATIO = 0.50
local DIAL_OUTER_RADIUS_RATIO = 0.47
local DIAL_INNER_RADIUS_RATIO = 0.58
local DIAL_SECTOR_RANGES = {
    { -150, -108 },
    { -104, -62 },
    { -58, -16 },
    { -12, 30 },
}

local function GetDialGeometry(width, height)
    local outerRadius = math.min(width, height)
        * DIAL_OUTER_RADIUS_RATIO
    local innerRadius = outerRadius * DIAL_INNER_RADIUS_RATIO
    return width * DIAL_CENTER_X_RATIO,
        height * DIAL_CENTER_Y_RATIO,
        innerRadius,
        outerRadius
end

local function GetDialSectorNodePosition(
    width,
    height,
    sectorIndex,
    nodeWidth,
    nodeHeight
)
    local cx, cy, innerRadius, outerRadius = GetDialGeometry(width, height)
    local sector = DIAL_SECTOR_RANGES[sectorIndex]
    local angle = math.rad((sector[1] + sector[2]) * 0.5)
    local radius = (innerRadius + outerRadius) * 0.5
    local left = cx + math.cos(angle) * radius - nodeWidth * 0.5
    local top = cy + math.sin(angle) * radius - nodeHeight * 0.5
    return math.max(0, math.min(width - nodeWidth, left)),
        math.max(0, math.min(height - nodeHeight, top))
end

local HUD_SHADOW = {
    { x = 6, y = 6, blur = 0, color = { 0, 0, 0, 82 } },
}
local BUTTON_SHADOW = {
    { x = 4, y = 4, blur = 0, color = { 0, 0, 0, 72 } },
}

-- 全项目 UI 使用同一套“漫画机械控制台”视觉语言；齿轮本体仍由 GearRenderer 绘制。
GameUI.Theme = UI.Theme.ExtendTheme(UI.Theme.defaultTheme, {
    fonts = {
        {
            family = "sans",
            weights = {
                normal = "Fonts/NotoSansCJKsc-Regular.otf",
                bold = "Fonts/NotoSansCJKsc-Regular.otf",
            },
        },
    },
    colors = {
        primary = { 24, 164, 205, 255 },
        primaryHover = { 45, 195, 231, 255 },
        primaryPressed = { 12, 110, 143, 255 },
        secondary = { 181, 125, 35, 255 },
        secondaryHover = { 225, 169, 58, 255 },
        secondaryPressed = { 119, 75, 22, 255 },
        background = { 9, 20, 29, 255 },
        surface = { 19, 35, 46, 252 },
        surfaceHover = { 29, 53, 67, 252 },
        text = { 240, 245, 247, 255 },
        textSecondary = { 169, 195, 205, 255 },
        border = { 5, 11, 16, 255 },
        borderFocus = { 104, 230, 247, 255 },
        success = { 62, 205, 142, 255 },
        successHover = { 86, 231, 166, 255 },
        warning = { 247, 180, 62, 255 },
        error = { 230, 75, 55, 255 },
        errorHover = { 247, 101, 78, 255 },
        info = { 77, 209, 236, 255 },
        disabled = { 49, 61, 67, 255 },
        disabledText = { 126, 139, 145, 255 },
    },
    radius = {
        none = 0,
        xs = 0,
        sm = 0,
        md = 0,
        lg = 0,
        xl = 0,
        full = 0,
    },
    componentDefaults = {
        borderRadius = 0,
        fontWeight = "bold",
    },
    components = {
        Button = {
            height = 44,
            borderWidth = { 2, 4, 5, 2 },
            borderRadius = 0,
            borderColor = { 5, 11, 16, 255 },
            boxShadow = BUTTON_SHADOW,
            fontWeight = "bold",
        },
        Card = {
            borderWidth = { 2, 4, 5, 2 },
            borderRadius = 0,
            borderColor = { 5, 11, 16, 255 },
            boxShadow = HUD_SHADOW,
        },
        ProgressBar = {
            height = 10,
            borderRadius = 0,
        },
        Modal = {
            borderWidth = 3,
            borderRadius = 0,
            boxShadow = HUD_SHADOW,
        },
    },
})

---@class GearIcon : Widget
---@overload fun(props?: table): GearIcon
---@field gearType_ string
---@field blueprint_ boolean
local GearIcon = Widget:Extend("GearIcon")

function GearIcon:Init(props)
    props = props or {}
    props.width = props.width or 38
    props.height = props.height or 38
    props.flexShrink = props.flexShrink or 0
    props.pointerEvents = "none"
    self.gearType_ = props.gearType or "small"
    self.blueprint_ = props.blueprint == true
    Widget.Init(self, props)
end

local function DrawBlueprintGear(vg, cx, cy, size, gearType)
    local rootRadius = size * 0.25
    local tipRadius = size * 0.35
    local teeth = gearType == "large" and 12
        or gearType == "compound" and 10
        or gearType == "medium" and 10
        or 8
    local primary = gearType == "medium"
            and nvgRGBA(193, 172, 91, 235)
        or gearType == "compound"
            and nvgRGBA(198, 111, 67, 235)
        or nvgRGBA(137, 169, 180, 235)

    nvgBeginPath(vg)
    for index = 0, teeth * 4 - 1 do
        local toothPhase = index % 4
        local radius = (toothPhase == 1 or toothPhase == 2)
                and tipRadius
            or rootRadius
        local angle = math.pi * 2 * index / (teeth * 4) - math.pi * 0.5
        local x = cx + math.cos(angle) * radius
        local y = cy + math.sin(angle) * radius
        if index == 0 then
            nvgMoveTo(vg, x, y)
        else
            nvgLineTo(vg, x, y)
        end
    end
    nvgClosePath(vg)
    nvgStrokeColor(vg, primary)
    nvgStrokeWidth(vg, 1.8)
    nvgStroke(vg)
    nvgBeginPath(vg)
    nvgCircle(vg, cx, cy, rootRadius * 0.38)
    nvgStrokeColor(vg, nvgRGBA(210, 226, 229, 225))
    nvgStrokeWidth(vg, 1.5)
    nvgStroke(vg)
    if gearType == "compound" then
        nvgBeginPath(vg)
        nvgCircle(vg, cx, cy, rootRadius * 0.67)
        nvgStrokeColor(vg, nvgRGBA(225, 150, 73, 215))
        nvgStrokeWidth(vg, 1.5)
        nvgStroke(vg)
    end
end

function GearIcon:Render(vg)
    local layout = self:GetAbsoluteLayout()
    if self.blueprint_ then
        DrawBlueprintGear(
            vg,
            layout.x + layout.w * 0.5,
            layout.y + layout.h * 0.5,
            math.min(layout.w, layout.h),
            self.gearType_
        )
        return
    end
    GearRenderer.DrawShopGearIcon(
        vg,
        self.gearType_,
        layout.x + layout.w * 0.5,
        layout.y + layout.h * 0.5,
        math.min(layout.w, layout.h),
        1
    )
end

---@class HudLineIcon : Widget
---@overload fun(props?: table): HudLineIcon
---@field iconType_ string
---@field color_ integer[]
local HudLineIcon = Widget:Extend("HudLineIcon")

function HudLineIcon:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    self.iconType_ = props.iconType or "gear"
    self.color_ = props.color or { 238, 218, 164, 255 }
    Widget.Init(self, props)
end

local function StrokeHudPath(vg, color, width)
    nvgStrokeColor(vg, nvgRGBA(color[1], color[2], color[3], color[4] or 255))
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

function HudLineIcon:Render(vg)
    local layout = self:GetAbsoluteLayout()
    local cx = layout.x + layout.w * 0.5
    local cy = layout.y + layout.h * 0.5
    local size = math.min(layout.w, layout.h)
    local radius = size * 0.28
    local color = self.color_

    if self.iconType_ == "shaft" then
        nvgBeginPath(vg)
        nvgRect(vg, cx - radius * 0.55, cy - radius, radius * 1.1, radius * 2)
        StrokeHudPath(vg, color, 1.6)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx - radius, cy - radius * 0.72)
        nvgLineTo(vg, cx + radius, cy - radius * 0.72)
        nvgMoveTo(vg, cx - radius, cy + radius * 0.72)
        nvgLineTo(vg, cx + radius, cy + radius * 0.72)
        StrokeHudPath(vg, color, 1.6)
        nvgBeginPath(vg)
        nvgCircle(vg, cx, cy, radius * 0.34)
        StrokeHudPath(vg, color, 1.6)
    elseif self.iconType_ == "income" then
        DrawBlueprintGear(vg, cx, cy, size * 0.88, "medium")
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx + radius * 0.55, cy - radius * 0.7)
        nvgLineTo(vg, cx + radius * 1.15, cy - radius * 0.7)
        nvgLineTo(vg, cx + radius * 1.15, cy - radius * 1.05)
        StrokeHudPath(vg, color, 1.4)
    elseif self.iconType_ == "click" then
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx - radius * 0.15, cy + radius)
        nvgLineTo(vg, cx - radius * 0.15, cy - radius * 0.75)
        nvgLineTo(vg, cx + radius * 0.12, cy - radius)
        nvgLineTo(vg, cx + radius * 0.34, cy - radius * 0.72)
        nvgLineTo(vg, cx + radius * 0.34, cy - radius * 0.18)
        nvgLineTo(vg, cx + radius * 0.76, cy + radius * 0.05)
        nvgLineTo(vg, cx + radius * 0.62, cy + radius)
        StrokeHudPath(vg, color, 1.7)
        for index = -1, 1 do
            local angle = math.rad(-90 + index * 35)
            nvgBeginPath(vg)
            nvgMoveTo(
                vg,
                cx + math.cos(angle) * radius * 1.25,
                cy + math.sin(angle) * radius * 1.25
            )
            nvgLineTo(
                vg,
                cx + math.cos(angle) * radius * 1.55,
                cy + math.sin(angle) * radius * 1.55
            )
            StrokeHudPath(vg, color, 1.3)
        end
    elseif self.iconType_ == "permanent" then
        nvgBeginPath(vg)
        nvgCircle(vg, cx, cy, radius * 0.9)
        StrokeHudPath(vg, color, 1.6)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx + radius * 0.2, cy - radius * 1.05)
        nvgLineTo(vg, cx + radius * 0.85, cy - radius * 0.92)
        nvgLineTo(vg, cx + radius * 0.63, cy - radius * 0.35)
        StrokeHudPath(vg, color, 1.6)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx - radius * 0.2, cy + radius * 1.05)
        nvgLineTo(vg, cx - radius * 0.85, cy + radius * 0.92)
        nvgLineTo(vg, cx - radius * 0.63, cy + radius * 0.35)
        StrokeHudPath(vg, color, 1.6)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx, cy - radius * 0.45)
        nvgLineTo(vg, cx, cy + radius * 0.45)
        StrokeHudPath(vg, color, 1.4)
    else
        DrawBlueprintGear(vg, cx, cy, size * 0.9, "medium")
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx - radius * 0.75, cy + radius * 0.85)
        nvgLineTo(vg, cx + radius * 0.78, cy - radius * 0.68)
        nvgMoveTo(vg, cx + radius * 0.48, cy - radius * 0.88)
        nvgLineTo(vg, cx + radius * 0.92, cy - radius * 0.44)
        StrokeHudPath(vg, color, 1.8)
    end
end

---@class ImageIcon : Widget
---@overload fun(props?: table): ImageIcon
---@field imagePath_ string
local ImageIcon = Widget:Extend("ImageIcon")

function ImageIcon:Init(props)
    props = props or {}
    props.width = props.width or 38
    props.height = props.height or 38
    props.flexShrink = props.flexShrink or 0
    props.pointerEvents = "none"
    self.imagePath_ = props.imagePath
    Widget.Init(self, props)
end

function ImageIcon:Render(vg)
    local contextKey = tostring(vg)
    local contextHandles = imageIconHandlesByContext_[contextKey]
    if not contextHandles then
        contextHandles = {}
        imageIconHandlesByContext_[contextKey] = contextHandles
    end

    local imageHandle = contextHandles[self.imagePath_]
    if imageHandle == nil or imageHandle <= 0 then
        imageHandle = ImageCache.Get(self.imagePath_)
        if imageHandle and imageHandle > 0 then
            contextHandles[self.imagePath_] = imageHandle
            print(string.format(
                "[GameUI] UI 图标 PNG 已加载: handle=%s, path=%s",
                tostring(imageHandle),
                self.imagePath_
            ))
        else
            contextHandles[self.imagePath_] = nil
            print(string.format(
                "[GameUI] UI 图标 PNG 加载失败: path=%s",
                self.imagePath_
            ))
        end
    end
    if not imageHandle or imageHandle <= 0 then
        return
    end

    local layout = self:GetAbsoluteLayout()
    local size = math.min(layout.w, layout.h)
    local left = layout.x + (layout.w - size) * 0.5
    local top = layout.y + (layout.h - size) * 0.5
    nvgBeginPath(vg)
    nvgRect(vg, left, top, size, size)
    nvgFillPaint(vg, nvgImagePattern(
        vg,
        left,
        top,
        size,
        size,
        0,
        imageHandle,
        1
    ))
    nvgFill(vg)
end

---@class StretchImage : Widget
---@overload fun(props?: table): StretchImage
---@field imagePath_ string
local StretchImage = Widget:Extend("StretchImage")

function StretchImage:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    self.imagePath_ = props.imagePath
    Widget.Init(self, props)
end

function StretchImage:Render(vg)
    local contextKey = tostring(vg)
    local contextHandles = imageIconHandlesByContext_[contextKey]
    if not contextHandles then
        contextHandles = {}
        imageIconHandlesByContext_[contextKey] = contextHandles
    end

    local imageHandle = contextHandles[self.imagePath_]
    if imageHandle == nil or imageHandle <= 0 then
        imageHandle = ImageCache.Get(self.imagePath_)
        if imageHandle and imageHandle > 0 then
            contextHandles[self.imagePath_] = imageHandle
            print(string.format(
                "[GameUI] 拉伸框体 PNG 已加载: handle=%s, path=%s",
                tostring(imageHandle),
                self.imagePath_
            ))
        else
            contextHandles[self.imagePath_] = nil
            print(string.format(
                "[GameUI] ERROR: 拉伸框体 PNG 加载失败，将在下一帧重试: path=%s",
                self.imagePath_
            ))
        end
    end
    if not imageHandle or imageHandle <= 0 then
        return
    end

    local layout = self:GetAbsoluteLayout()
    nvgBeginPath(vg)
    nvgRect(vg, layout.x, layout.y, layout.w, layout.h)
    nvgFillPaint(vg, nvgImagePattern(
        vg,
        layout.x,
        layout.y,
        layout.w,
        layout.h,
        0,
        imageHandle,
        1
    ))
    nvgFill(vg)
end

---@class DirectionTriangle : Widget
---@overload fun(props?: table): DirectionTriangle
---@field direction_ string
local DirectionTriangle = Widget:Extend("DirectionTriangle")

function DirectionTriangle:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    self.direction_ = props.direction or "right"
    Widget.Init(self, props)
end

function DirectionTriangle:Render(vg)
    local layout = self:GetAbsoluteLayout()
    local cx = layout.x + layout.w * 0.5
    local cy = layout.y + layout.h * 0.5
    local halfWidth = math.min(layout.w * 0.21, layout.h * 0.18)
    local halfHeight = math.min(layout.h * 0.23, layout.w * 0.25)

    nvgBeginPath(vg)
    if self.direction_ == "left" then
        nvgMoveTo(vg, cx - halfWidth, cy)
        nvgLineTo(vg, cx + halfWidth, cy - halfHeight)
        nvgLineTo(vg, cx + halfWidth, cy + halfHeight)
    else
        nvgMoveTo(vg, cx + halfWidth, cy)
        nvgLineTo(vg, cx - halfWidth, cy - halfHeight)
        nvgLineTo(vg, cx - halfWidth, cy + halfHeight)
    end
    nvgClosePath(vg)
    nvgFillColor(vg, nvgRGBA(74, 237, 255, 255))
    nvgFill(vg)
end

---@class MechanicalLoadGauge : Widget
---@overload fun(props?: table): MechanicalLoadGauge
---@field props table
local MechanicalLoadGauge = Widget:Extend("MechanicalLoadGauge")

MechanicalLoadGauge.transitionableProps_ = { value = "number" }

function MechanicalLoadGauge:Init(props)
    props = props or {}
    props.value = props.value or 0
    props.max = props.max or 1
    props.fillColor = props.fillColor or { 44, 222, 245, 255 }
    props.trackColor = props.trackColor or { 16, 65, 82, 220 }
    props.pointerEvents = "none"
    Widget.Init(self, props)
end

function MechanicalLoadGauge:Render(vg)
    local layout = self:GetAbsoluteLayout()
    local props = self.props
    local value = self.renderProps_.value or props.value or 0
    local maximum = math.max(0.0001, props.max or 1)
    local progress = math.max(0, math.min(1, value / maximum))
    local fillColor = props.fillColor or { 84, 215, 153, 255 }
    local trackColor = props.trackColor or { 16, 65, 82, 220 }
    local x = layout.x + 5
    local width = math.max(1, layout.w - 10)
    local labelY = layout.y + math.min(7, layout.h * 0.2)
    local trackY = layout.y + layout.h * 0.72
    local segmentCount = 20
    local segmentStep = width / segmentCount
    local segmentGap = math.min(4, segmentStep * 0.24)
    local segmentHeight = math.max(3, math.min(4, layout.h * 0.11))

    nvgFontFace(vg, UI.Theme.FontFamily())
    nvgFontSize(vg, math.max(8, math.min(10, layout.h * 0.28)))
    nvgTextAlign(vg, NVG_ALIGN_CENTER_VISUAL + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, nvgRGBA(72, 176, 195, 215))
    for index, label in ipairs({ "25%", "50%", "75%", "100%" }) do
        nvgText(vg, x + width * index * 0.25, labelY, label)
    end

    nvgBeginPath(vg)
    nvgMoveTo(vg, x, trackY)
    nvgLineTo(vg, x + width, trackY)
    nvgStrokeColor(vg, nvgRGBA(7, 35, 50, 245))
    nvgStrokeWidth(vg, segmentHeight + 3)
    nvgStroke(vg)

    for index = 1, segmentCount do
        local segmentX = x + (index - 1) * segmentStep + segmentGap * 0.5
        local segmentWidth = math.max(2, segmentStep - segmentGap)
        local segmentProgress = (index - 0.5) / segmentCount
        local isActive = segmentProgress <= progress
        local color = isActive and fillColor or trackColor

        if isActive then
            nvgBeginPath(vg)
            nvgRoundedRect(
                vg,
                segmentX - 1,
                trackY - segmentHeight * 0.5 - 1,
                segmentWidth + 2,
                segmentHeight + 2,
                segmentHeight * 0.5
            )
            nvgFillColor(vg, nvgRGBA(
                fillColor[1],
                fillColor[2],
                fillColor[3],
                58
            ))
            nvgFill(vg)
        end

        nvgBeginPath(vg)
        nvgRoundedRect(
            vg,
            segmentX,
            trackY - segmentHeight * 0.5,
            segmentWidth,
            segmentHeight,
            segmentHeight * 0.5
        )
        nvgFillColor(vg, nvgRGBA(
            color[1],
            color[2],
            color[3],
            color[4] or 255
        ))
        nvgFill(vg)
    end

    for index = 1, 4 do
        local tickX = x + width * index * 0.25
        nvgBeginPath(vg)
        nvgMoveTo(vg, tickX, trackY - 7)
        nvgLineTo(vg, tickX, trackY + 7)
        nvgStrokeColor(vg, nvgRGBA(39, 180, 207, 225))
        nvgStrokeWidth(vg, 1)
        nvgStroke(vg)
    end

    nvgBeginPath(vg)
    nvgCircle(vg, x, trackY, 3.2)
    nvgFillColor(vg, nvgRGBA(44, 222, 245, 255))
    nvgFill(vg)

    if progress > 0 then
        local markerX = x + width * progress
        nvgBeginPath(vg)
        nvgCircle(vg, markerX, trackY, 3.4)
        nvgFillColor(vg, nvgRGBA(
            fillColor[1],
            fillColor[2],
            fillColor[3],
            fillColor[4] or 255
        ))
        nvgFill(vg)
    end
end

function MechanicalLoadGauge:SetValue(value)
    local clamped = math.max(0, math.min(self.props.max or 1, value))
    self:SetStyle({ value = clamped })
    return self
end

function MechanicalLoadGauge:GetValue()
    return self.props.value
end

function MechanicalLoadGauge:SetMax(maximum)
    self.props.max = maximum
    return self
end

---@class BlueprintTrayBackdrop : Widget
---@overload fun(props?: table): BlueprintTrayBackdrop
local BlueprintTrayBackdrop = Widget:Extend("BlueprintTrayBackdrop")

function BlueprintTrayBackdrop:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    Widget.Init(self, props)
end

function BlueprintTrayBackdrop:Render(vg)
    local layout = self:GetAbsoluteLayout()
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    local cut = math.min(18, h * 0.22)

    nvgBeginPath(vg)
    nvgMoveTo(vg, x + cut, y)
    nvgLineTo(vg, x + w - cut, y)
    nvgLineTo(vg, x + w, y + cut)
    nvgLineTo(vg, x + w, y + h - cut)
    nvgLineTo(vg, x + w - cut, y + h)
    nvgLineTo(vg, x + cut, y + h)
    nvgLineTo(vg, x, y + h - cut)
    nvgLineTo(vg, x, y + cut)
    nvgClosePath(vg)
    nvgFillColor(vg, nvgRGBA(4, 28, 43, 205))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(67, 222, 244, 210))
    nvgStrokeWidth(vg, 1.5)
    nvgStroke(vg)

    nvgBeginPath(vg)
    nvgMoveTo(vg, x + cut + 8, y + 7)
    nvgLineTo(vg, x + w - cut - 8, y + 7)
    nvgStrokeColor(vg, nvgRGBA(118, 239, 252, 90))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)
end

---@class UpgradeDialBackdrop : Widget
---@overload fun(props?: table): UpgradeDialBackdrop
---@field expanded_ boolean
local UpgradeDialBackdrop = Widget:Extend("UpgradeDialBackdrop")

function UpgradeDialBackdrop:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    self.expanded_ = props.expanded == true
    Widget.Init(self, props)
end

function UpgradeDialBackdrop:SetExpanded(expanded)
    self.expanded_ = expanded == true
end

local function BeginDialSectorPath(
    vg,
    cx,
    cy,
    innerRadius,
    outerRadius,
    startAngle,
    endAngle
)
    local steps = 16
    nvgBeginPath(vg)
    for step = 0, steps do
        local t = step / steps
        local angle = startAngle + (endAngle - startAngle) * t
        local x = cx + math.cos(angle) * outerRadius
        local y = cy + math.sin(angle) * outerRadius
        if step == 0 then
            nvgMoveTo(vg, x, y)
        else
            nvgLineTo(vg, x, y)
        end
    end
    for step = steps, 0, -1 do
        local t = step / steps
        local angle = startAngle + (endAngle - startAngle) * t
        nvgLineTo(
            vg,
            cx + math.cos(angle) * innerRadius,
            cy + math.sin(angle) * innerRadius
        )
    end
    nvgClosePath(vg)
end

local function DrawDialSector(
    vg,
    cx,
    cy,
    innerRadius,
    outerRadius,
    startAngle,
    endAngle
)
    BeginDialSectorPath(
        vg,
        cx,
        cy,
        innerRadius,
        outerRadius,
        startAngle,
        endAngle
    )
    local fill = nvgRadialGradient(
        vg,
        cx,
        cy,
        innerRadius,
        outerRadius,
        nvgRGBA(13, 62, 79, 220),
        nvgRGBA(3, 24, 39, 238)
    )
    nvgFillPaint(vg, fill)
    nvgFill(vg)

    -- 参考图的青色光边：宽光晕、中层亮边和清晰芯线。
    nvgStrokeColor(vg, nvgRGBA(29, 226, 255, 28))
    nvgStrokeWidth(vg, 10)
    nvgStroke(vg)
    nvgStrokeColor(vg, nvgRGBA(41, 230, 255, 72))
    nvgStrokeWidth(vg, 5)
    nvgStroke(vg)
    nvgStrokeColor(vg, nvgRGBA(88, 235, 252, 235))
    nvgStrokeWidth(vg, 1.5)
    nvgStroke(vg)

    -- 外弧高光让扇区拥有玻璃切边质感。
    local highlightRadius = outerRadius - 2
    local highlightStart = startAngle + math.rad(3)
    local highlightEnd = endAngle - math.rad(3)
    nvgBeginPath(vg)
    for step = 0, 12 do
        local t = step / 12
        local angle = highlightStart
            + (highlightEnd - highlightStart) * t
        local x = cx + math.cos(angle) * highlightRadius
        local y = cy + math.sin(angle) * highlightRadius
        if step == 0 then
            nvgMoveTo(vg, x, y)
        else
            nvgLineTo(vg, x, y)
        end
    end
    nvgStrokeColor(vg, nvgRGBA(191, 250, 255, 190))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)
end

function UpgradeDialBackdrop:Render(vg)
    local layout = self:GetAbsoluteLayout()
    local localCx, localCy, innerRadius, outerRadius = GetDialGeometry(
        layout.w,
        layout.h
    )
    local cx = layout.x + localCx
    local cy = layout.y + localCy

    if self.expanded_ then
        for _, sector in ipairs(DIAL_SECTOR_RANGES) do
            DrawDialSector(
                vg,
                cx,
                cy,
                innerRadius,
                outerRadius,
                math.rad(sector[1]),
                math.rad(sector[2])
            )
        end

        nvgBeginPath(vg)
        nvgCircle(vg, cx, cy, innerRadius * 1.10)
        nvgStrokeColor(vg, nvgRGBA(29, 226, 255, 30))
        nvgStrokeWidth(vg, 9)
        nvgStroke(vg)
        nvgStrokeColor(vg, nvgRGBA(78, 231, 249, 135))
        nvgStrokeWidth(vg, 1.5)
        nvgStroke(vg)
    end

    local coreRadius = innerRadius * 0.86
    nvgBeginPath(vg)
    nvgCircle(vg, cx, cy, coreRadius)
    local coreFill = nvgRadialGradient(
        vg,
        cx,
        cy,
        coreRadius * 0.32,
        coreRadius,
        nvgRGBA(22, 49, 58, 246),
        nvgRGBA(3, 18, 29, 250)
    )
    nvgFillPaint(vg, coreFill)
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(255, 186, 38, 36))
    nvgStrokeWidth(vg, 12)
    nvgStroke(vg)
    nvgStrokeColor(vg, nvgRGBA(255, 198, 64, 92))
    nvgStrokeWidth(vg, 6)
    nvgStroke(vg)
    nvgStrokeColor(vg, nvgRGBA(255, 211, 96, 250))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)

    nvgBeginPath(vg)
    nvgCircle(vg, cx, cy, coreRadius * 0.88)
    nvgStrokeColor(vg, nvgRGBA(255, 238, 170, 90))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)
end

local function CreateGearShopCard(options)
    local priceLabel = UI.Label {
        text = options.priceText,
        fontSize = 10,
        fontWeight = "bold",
        fontColor = { 255, 203, 92, 255 },
        textAlign = "center",
        flexShrink = 1,
        pointerEvents = "none",
    }
    local shopIconPath = HUD_B_ICON_PATHS[options.gearType]
    local gearImage
    if shopIconPath then
        gearImage = ImageIcon {
            width = 44,
            height = 44,
            flexShrink = 0,
            imagePath = shopIconPath,
            pointerEvents = "none",
        }
    else
        gearImage = GearIcon {
            width = 44,
            height = 44,
            flexShrink = 0,
            gearType = options.gearType,
            pointerEvents = "none",
        }
    end
    local lockedQuestionIcon = ImageIcon {
        visible = false,
        width = 44,
        height = 44,
        flexShrink = 0,
        imagePath = LOCKED_QUESTION_ICON_PATH,
        pointerEvents = "none",
    }
    local gearIconSlot = UI.Panel {
        width = 52,
        height = 52,
        minWidth = 52,
        flexGrow = 0,
        flexShrink = 0,
        alignItems = "center",
        justifyContent = "center",
        pointerEvents = "none",
        children = { gearImage, lockedQuestionIcon },
    }
    local modelLabel = UI.Label {
        text = options.model,
        fontSize = 10,
        fontWeight = "bold",
        fontColor = { 226, 234, 239, 255 },
        textAlign = "center",
        flexShrink = 1,
        pointerEvents = "none",
    }
    local lockedStatusLabel = UI.Label {
        text = "未解锁",
        visible = false,
        fontSize = 9,
        fontWeight = "bold",
        fontColor = { 83, 225, 245, 255 },
        textAlign = "left",
        pointerEvents = "none",
    }
    local lockedActionLabel = UI.Label {
        text = "未解锁",
        visible = false,
        width = 58,
        height = 28,
        paddingTop = 6,
        fontSize = 9,
        fontWeight = "bold",
        fontColor = { 170, 185, 191, 255 },
        textAlign = "center",
        backgroundColor = { 28, 38, 44, 245 },
        borderWidth = 1,
        borderColor = { 91, 112, 122, 210 },
        borderRadius = 0,
        pointerEvents = "none",
    }
    local infoPanel = UI.Panel {
        flexGrow = 1,
        flexShrink = 1,
        minWidth = 0,
        paddingRight = 10,
        gap = 1,
        justifyContent = "center",
        pointerEvents = "none",
        children = {
            modelLabel,
            lockedStatusLabel,
            priceLabel,
        },
    }
    local slotLabel = UI.Label {
        text = options.slotNumber or "",
        visible = options.slotNumber ~= nil,
        position = "absolute",
        top = 2,
        right = 4,
        fontSize = 8,
        fontWeight = "bold",
        fontColor = { 190, 246, 255, 245 },
        pointerEvents = "none",
    }
    local countLabel = UI.Label {
        text = options.slotNumber or "",
        visible = options.slotNumber ~= nil,
        position = "absolute",
        bottom = 7,
        right = 8,
        width = 21,
        height = 21,
        fontSize = 9,
        fontWeight = "bold",
        fontColor = { 190, 246, 255, 245 },
        textAlign = "center",
        pointerEvents = "none",
    }
    local cardFramePath = SIDE_RAIL_IMAGE_PATHS.shopCard
    if options.gearType == "small" then
        cardFramePath = SIDE_RAIL_IMAGE_PATHS.shopCardSmall
    elseif options.gearType == "medium" then
        cardFramePath = SIDE_RAIL_IMAGE_PATHS.shopCardMedium
    elseif options.gearType == "large" then
        cardFramePath = SIDE_RAIL_IMAGE_PATHS.shopCardLarge
    elseif options.gearType == "compound" then
        cardFramePath = SIDE_RAIL_IMAGE_PATHS.shopCardCompound
    end
    local card = UI.Card {
        variant = "outlined",
        clickable = true,
        hoverable = true,
        height = 92,
        flexGrow = 1,
        flexBasis = 0,
        padding = 5,
        borderColor = { 211, 159, 53, 235 },
        backgroundColor = { 24, 31, 37, 250 },
        flexDirection = "row",
        alignItems = "center",
        justifyContent = "center",
        gap = 7,
        children = {
            StretchImage {
                visible = false,
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                bottom = 0,
                imagePath = cardFramePath,
            },
            gearIconSlot,
            infoPanel,
            lockedActionLabel,
            slotLabel,
            countLabel,
        },
    }
    card.OnPointerDown = function(_, event)
        if not card.props.clickable or not event:IsPrimaryAction() then
            return
        end
        card:SetState({ pressed = true })
    end
    card.OnPointerUp = function()
        card:SetState({ pressed = false })
    end
    card.OnPointerCancel = function()
        card:SetState({ pressed = false })
    end
    card.props.shopGearType = options.gearType
    card.props.revealedModelText = options.model
    card.props.hasSlotNumber = options.slotNumber ~= nil
    card.props.frameImage = card.children[1]
    card.props.gearImage = gearImage
    card.props.lockedQuestionIcon = lockedQuestionIcon
    card.props.gearIconSlot = gearIconSlot
    card.props.infoPanel = infoPanel
    card.props.lockedStatusLabel = lockedStatusLabel
    card.props.lockedActionLabel = lockedActionLabel
    card.props.slotLabel = slotLabel
    card.props.countLabel = countLabel
    card.props.modelLabel = modelLabel
    card.props.priceLabel = priceLabel
    return card, priceLabel
end

local function CreateGearUpgradeCard(options)
    local priceLabel = UI.Label {
        text = options.priceText,
        fontSize = 12,
        fontWeight = "bold",
        fontColor = { 255, 203, 92, 255 },
        textAlign = "center",
        flexShrink = 1,
        pointerEvents = "none",
    }
    local effectLabel = UI.Label {
        text = options.effectText,
        fontSize = 8,
        fontWeight = "bold",
        fontColor = { 132, 231, 245, 245 },
        textAlign = "center",
        flexShrink = 1,
        pointerEvents = "none",
    }
    local gearImage
    if options.hudIconType then
        gearImage = ImageIcon {
            width = 38,
            height = 38,
            flexShrink = 0,
            imagePath = HUD_B_ICON_PATHS[options.hudIconType],
            pointerEvents = "none",
        }
    elseif options.iconPath then
        gearImage = ImageIcon {
            width = 28,
            height = 28,
            flexShrink = 0,
            imagePath = options.iconPath,
            pointerEvents = "none",
        }
    else
        gearImage = GearIcon {
            width = 28,
            height = 28,
            flexShrink = 0,
            gearType = options.gearType or "main",
            pointerEvents = "none",
        }
    end
    local lockedQuestionIcon = ImageIcon {
        visible = false,
        width = 38,
        height = 38,
        flexShrink = 0,
        imagePath = LOCKED_QUESTION_ICON_PATH,
        pointerEvents = "none",
    }
    local titleLabel = UI.Label {
        text = options.title,
        fontSize = 9,
        fontWeight = "bold",
        fontColor = { 226, 234, 239, 255 },
        textAlign = "center",
        flexShrink = 1,
        pointerEvents = "none",
    }
    local actionLabel = UI.Label {
        text = "升级",
        visible = false,
        fontSize = 9,
        fontWeight = "bold",
        fontColor = { 255, 225, 151, 255 },
        textAlign = "center",
        pointerEvents = "none",
    }
    local card = UI.Card {
        variant = "outlined",
        clickable = true,
        hoverable = true,
        height = 76,
        flexGrow = 1,
        flexBasis = 0,
        flexShrink = 1,
        padding = 4,
        borderColor = { 62, 190, 218, 235 },
        backgroundColor = { 18, 39, 49, 250 },
        flexDirection = "column",
        alignItems = "center",
        justifyContent = "center",
        gap = 2,
        onClick = options.onClick,
        children = {
            StretchImage {
                visible = false,
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                bottom = 0,
                imagePath = SIDE_RAIL_IMAGE_PATHS.upgradeCard,
            },
            gearImage,
            lockedQuestionIcon,
            titleLabel,
            effectLabel,
            priceLabel,
            actionLabel,
        },
    }
    card.SetText = function(_, text)
        local lines = {}
        for line in (text .. "\n"):gmatch("([^\n]*)\n") do
            lines[#lines + 1] = line
        end

        titleLabel:SetText(lines[1] or text)
        if #lines >= 3 then
            effectLabel:SetText(lines[2] or "")
            priceLabel:SetText(lines[3] or "")
        elseif (lines[2] or ""):match("^Lv%.") then
            effectLabel:SetText(lines[2] or "")
            priceLabel:SetText("")
        else
            effectLabel:SetText("")
            priceLabel:SetText(lines[2] or "")
        end
    end
    card.SetDisabled = function(_, disabled)
        card:SetClickable(not disabled)
        card:SetOpacity(disabled and 0.72 or 1)
    end
    card.props.frameImage = card.children[1]
    card.props.gearImage = gearImage
    card.props.lockedQuestionIcon = lockedQuestionIcon
    card.props.modelLabel = titleLabel
    card.props.priceLabel = priceLabel
    card.props.effectLabel = effectLabel
    card.props.actionLabel = actionLabel
    return card
end

---@param callbacks table
---@return table
function GameUI.Create(callbacks)
    local isLandscapeLayout = callbacks.layoutMode == "landscape"
    if isLandscapeLayout then
        landscapeLeftRailCollapsed_ = true
        landscapeRightRailCollapsed_ = true
    end
    local coinLabel = UI.Label {
        text = "￥  0",
        fontSize = 18,
        fontWeight = "bold",
        fontColor = { 255, 224, 130, 255 },
        flexShrink = 1,
    }

    local clickValueLabel = UI.Label {
        text = "每次点击  +1",
        fontSize = 11,
        fontColor = { 206, 213, 228, 230 },
    }

    local revenueLabel = UI.Label {
        text = "全网平均产能  ￥0.00/秒",
        fontSize = 10,
        textAlign = "right",
        fontColor = { 113, 232, 163, 245 },
        flexShrink = 1,
    }

    local essenceLabel = UI.Label {
        text = "齿轮精华  0",
        fontSize = 10,
        textAlign = "right",
        fontColor = { 130, 208, 255, 245 },
        flexShrink = 1,
    }

    local powerStatusLabel = UI.Label {
        text = "待解锁自动运转\n当前负载 / 总扭矩  0 / 0",
        fontSize = 9,
        lineHeight = 1.3,
        fontColor = { 213, 221, 236, 245 },
        flexShrink = 1,
    }

    local loadGaugeLabel = UI.Label {
        text = "负载占用  0%",
        fontSize = 10,
        fontWeight = "bold",
        fontColor = { 124, 207, 231, 245 },
        pointerEvents = "none",
    }

    local loadProgressBar = MechanicalLoadGauge {
        value = 0,
        max = 1,
        height = 34,
        fillColor = { 44, 222, 245, 255 },
        trackColor = { 16, 65, 82, 220 },
        transition = "value 0.2s easeOut",
        pointerEvents = "none",
    }

    local levelLabel = UI.Label {
        text = "点击收益等级  Lv.1",
        fontSize = 14,
        fontColor = { 236, 239, 247, 255 },
    }

    local shopInfoLabel = UI.Label {
        text = "已购 0 · 咬合 0 · 驱动 0",
        fontSize = 9,
        textAlign = "right",
        fontColor = { 170, 181, 202, 235 },
        flexShrink = 1,
    }

    local idleEarningsButton = UI.Button {
        text = "挂机 0/2",
        variant = "secondary",
        visible = true,
        height = 30,
        minWidth = 76,
        flexShrink = 0,
        fontSize = 10,
        fontWeight = "bold",
        paddingLeft = 8,
        paddingRight = 8,
        textColor = { 255, 226, 142, 255 },
        backgroundColor = { 49, 36, 14, 235 },
        hoverBackgroundColor = { 86, 60, 18, 250 },
        pressedBackgroundColor = { 30, 22, 9, 255 },
        borderColor = { 241, 178, 64, 240 },
        borderWidth = 1,
        borderRadius = 15,
        onClick = function()
            callbacks.openIdleEarnings()
        end,
    }

    local layoutToggleButton = UI.Button {
        visible = false,
        text = "竖版",
        variant = "secondary",
        height = 30,
        minWidth = 52,
        flexShrink = 0,
        fontSize = 10,
        paddingLeft = 8,
        paddingRight = 8,
        onClick = function()
            callbacks.toggleLayoutMode()
        end,
    }

    ---@type Widget
    local clickUpgradeDetailsPanel = nil
    ---@type Button
    local clickUpgradeConfirmButton = nil
    local clickUpgradeTitleLabel = UI.Label {
        text = "点击收益",
        fontSize = 15,
        fontWeight = "bold",
        fontColor = { 223, 239, 243, 255 },
        width = "100%",
        flexShrink = 1,
        whiteSpace = "nowrap",
        pointerEvents = "none",
    }
    local clickUpgradeDescriptionLabel = UI.Label {
        text = "• 每次点击立即获得金币，并追加一整圈快速旋转动画；升级后点击收益增加30%",
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
        width = "100%",
        flexShrink = 1,
        whiteSpace = "nowrap",
        lineHeight = 1.3,
        pointerEvents = "none",
    }
    local clickUpgradeCurrentLabel = UI.Label {
        text = "• 当前每次点击立即获得￥1.00",
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
        width = "100%",
        flexShrink = 1,
        whiteSpace = "nowrap",
        lineHeight = 1.3,
        pointerEvents = "none",
    }
    local clickUpgradeResultLabel = UI.Label {
        text = "• 升级后每次点击立即获得￥1.30",
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
        width = "100%",
        flexShrink = 1,
        whiteSpace = "nowrap",
        lineHeight = 1.3,
        pointerEvents = "none",
    }
    local activeMainUpgradeType = nil

    local function RefreshMainUpgradeDetails()
        if not activeMainUpgradeType then
            return
        end
        local details = callbacks.getMainUpgradeDetails(
            activeMainUpgradeType
        )
        clickUpgradeTitleLabel:SetText(details.titleText)
        clickUpgradeDescriptionLabel:SetText(details.descriptionText)
        clickUpgradeCurrentLabel:SetText(details.currentText)
        clickUpgradeResultLabel:SetText(details.resultText)
        clickUpgradeConfirmButton:SetText(details.buttonText)
        clickUpgradeConfirmButton:SetDisabled(not details.canUpgrade)
    end

    local POPUP_MARGIN = 8
    local POPUP_WIDTH = 310
    local POPUP_HEIGHT = 200
    local POPUP_UPWARD_OFFSET = 32
    local POPUP_GAP = 12
    local POPUP_SHADOW_EXTENT = 6

    local function ClampMainUpgradeDetailsToScreen(sourceCard)
        local cardLayout = sourceCard:GetAbsoluteLayoutForHitTest()
        local layoutWidth = math.max(1, callbacks.layoutWidth or POPUP_WIDTH)
        local layoutHeight = math.max(1, callbacks.layoutHeight or POPUP_HEIGHT)
        local availableWidth = math.max(
            1,
            layoutWidth - POPUP_MARGIN * 2 - POPUP_SHADOW_EXTENT
        )
        local availableHeight = math.max(
            1,
            layoutHeight - POPUP_MARGIN * 2 - POPUP_SHADOW_EXTENT
        )
        local popupWidth = math.min(POPUP_WIDTH, availableWidth)
        local popupHeight = math.min(POPUP_HEIGHT, availableHeight)
        local maxLeft = math.max(
            POPUP_MARGIN,
            layoutWidth
                - popupWidth
                - POPUP_MARGIN
                - POPUP_SHADOW_EXTENT
        )
        local maxTop = math.max(
            POPUP_MARGIN,
            layoutHeight
                - popupHeight
                - POPUP_MARGIN
                - POPUP_SHADOW_EXTENT
        )
        clickUpgradeDetailsPanel:SetStyle({
            left = math.min(
                math.max(
                    POPUP_MARGIN,
                    cardLayout.x - popupWidth - POPUP_GAP
                ),
                maxLeft
            ),
            top = math.min(
                math.max(
                    POPUP_MARGIN,
                    cardLayout.y - POPUP_UPWARD_OFFSET
                ),
                maxTop
            ),
            width = popupWidth,
            height = popupHeight,
            minHeight = 0,
            overflow = "hidden",
        })
    end

    local function HideMainUpgradeDetails()
        activeMainUpgradeType = nil
        clickUpgradeDetailsPanel:SetVisible(false)
    end

    local function ToggleMainUpgradeDetails(upgradeType, sourceCard)
        if clickUpgradeDetailsPanel:IsVisible()
            and activeMainUpgradeType == upgradeType then
            HideMainUpgradeDetails()
            return
        end

        callbacks.preparePopupOpen("mainUpgrade")
        activeMainUpgradeType = upgradeType
        RefreshMainUpgradeDetails()
        clickUpgradeDetailsPanel:SetVisible(true)
        ClampMainUpgradeDetailsToScreen(sourceCard)
    end

    clickUpgradeConfirmButton = UI.Button {
        text = "升级  ￥10",
        variant = "secondary",
        height = 38,
        width = "100%",
        fontSize = 11,
        fontWeight = "bold",
        textColor = { 78, 28, 110, 255 },
        backgroundColor = { 255, 255, 255, 255 },
        disabledBackgroundColor = { 103, 38, 147, 255 },
        hoverBackgroundColor = { 248, 231, 255, 255 },
        pressedBackgroundColor = { 225, 203, 236, 255 },
        borderColor = { 255, 255, 255, 255 },
        borderWidth = 2,
        borderRadius = 0,
        onClick = function()
            if activeMainUpgradeType == "manualClick" then
                callbacks.upgradeClickValue()
            elseif activeMainUpgradeType == "torque" then
                callbacks.upgradeMainTorque()
            elseif activeMainUpgradeType == "circleIncome" then
                callbacks.upgradeMainCircleIncome()
            end
            RefreshMainUpgradeDetails()
        end,
    }
    clickUpgradeDetailsPanel = UI.Panel {
        visible = false,
        position = "absolute",
        left = 8,
        top = 8,
        width = 236,
        minHeight = 190,
        paddingTop = 22,
        paddingRight = 16,
        paddingBottom = 22,
        paddingLeft = 16,
        gap = 10,
        backgroundColor = { 18, 35, 47, 255 },
        backgroundGradient = {
            type = "linear",
            direction = 45,
            from = { 27, 76, 94, 255 },
            to = { 18, 35, 47, 255 },
        },
        borderColor = { 92, 210, 230, 255 },
        borderWidth = 2,
        borderRadius = 0,
        boxShadow = {
            { x = 6, y = 6, blur = 0, color = { 0, 0, 0, 90 } },
        },
        pointerEvents = "auto",
        children = {
            clickUpgradeTitleLabel,
            clickUpgradeDescriptionLabel,
            clickUpgradeCurrentLabel,
            clickUpgradeResultLabel,
            clickUpgradeConfirmButton,
        },
    }
    clickUpgradeDetailsPanel.props.resultLabel = clickUpgradeResultLabel

    ---@type Card
    local upgradeButton = nil
    upgradeButton = CreateGearUpgradeCard {
        title = "提升点击收益",
        effectText = "下级：点击 +30%",
        priceText = "查看详情",
        hudIconType = "click",
        onClick = function()
            ToggleMainUpgradeDetails("manualClick", upgradeButton)
        end,
    }
    local clickUpgradeWrapper = UI.Panel {
        position = "relative",
        flexGrow = 1,
        flexBasis = 0,
        minWidth = 0,
        overflow = "visible",
        pointerEvents = "box-none",
        children = {
            upgradeButton,
        },
    }

    ---@type Card
    local mainTorqueUpgradeButton = nil
    mainTorqueUpgradeButton = CreateGearUpgradeCard {
        title = "给主齿轮力量",
        effectText = "下级：总扭矩 0.25",
        priceText = "￥25",
        hudIconType = "shaft",
        onClick = function()
            if isLandscapeLayout then
                ToggleMainUpgradeDetails(
                    "torque",
                    mainTorqueUpgradeButton
                )
                if callbacks.tutorialNotify then
                    callbacks.tutorialNotify("torque_selected")
                end
            else
                callbacks.upgradeMainTorque()
            end
        end,
    }
    ---@type Card
    local mainCircleIncomeUpgradeButton = nil
    mainCircleIncomeUpgradeButton = CreateGearUpgradeCard {
        title = "单个主齿轮收益",
        effectText = "仅中央主齿轮每圈 +1",
        priceText = "￥40",
        hudIconType = "income",
        onClick = function()
            if isLandscapeLayout then
                ToggleMainUpgradeDetails(
                    "circleIncome",
                    mainCircleIncomeUpgradeButton
                )
            else
                callbacks.upgradeMainCircleIncome()
            end
        end,
    }

    local buySmallGearButton, buySmallGearPriceLabel = CreateGearShopCard {
        model = "S-16  小型",
        priceText = "￥100",
        slotNumber = "1",
        gearType = "small",
        onDragStart = callbacks.shopGearDragStart,
    }

    local buyMediumGearButton, buyMediumGearPriceLabel = CreateGearShopCard {
        model = "M-24  中型",
        priceText = "￥250",
        slotNumber = "2",
        gearType = "medium",
        onDragStart = callbacks.shopGearDragStart,
    }

    local buyLargeGearButton, buyLargeGearPriceLabel = CreateGearShopCard {
        model = "L-32  大型",
        priceText = "￥500",
        slotNumber = "3",
        gearType = "large",
        onDragStart = callbacks.shopGearDragStart,
    }

    local buyCompoundGearButton, buyCompoundGearPriceLabel = CreateGearShopCard {
        model = "C-24/12  双层",
        priceText = "￥1000",
        slotNumber = "4",
        gearType = "compound",
        onDragStart = callbacks.shopGearDragStart,
    }

    local buyMommaGearButton, buyMommaGearPriceLabel = CreateGearShopCard {
        model = "MG-40/20  母齿轮",
        priceText = "￥2500",
        gearType = "momma",
        onDragStart = callbacks.shopGearDragStart,
    }

    local buyLubricantGearButton, buyLubricantGearPriceLabel = CreateGearShopCard {
        model = "OIL-08  巡游润滑",
        priceText = "￥750",
        gearType = "lubricant",
        onDragStart = callbacks.shopGearDragStart,
    }

    local buyCoinGearButton, buyCoinGearPriceLabel = CreateGearShopCard {
        model = "COIN-32  金币齿轮",
        priceText = "￥5000",
        gearType = "coin",
        onDragStart = callbacks.shopGearDragStart,
    }

    local factoryStatusLabel = UI.Label {
        text = "巨型齿轮工厂 · 未解锁",
        fontSize = 11,
        lineHeight = 1.3,
        fontColor = { 132, 222, 174, 245 },
        flexShrink = 1,
        pointerEvents = "none",
    }

    local factoryClaimButton = UI.Button {
        text = "领取母齿轮",
        variant = "success",
        width = 64,
        height = 38,
        flexShrink = 0,
        onClick = function()
            callbacks.claimMommaFactoryGear()
        end,
    }

    local autoDriveButton = UI.Button {
        text = "自动运转：扭矩首次升级后解锁",
        variant = "secondary",
        width = 64,
        height = 38,
        alignSelf = "stretch",
        backgroundColor = { 48, 56, 61, 255 },
        borderColor = { 104, 116, 124, 210 },
        fontColor = { 164, 174, 180, 255 },
        onClick = function()
            callbacks.showAutoDriveRequirement()
        end,
    }

    local gearDetailsTitleLabel = UI.Label {
        text = "齿轮详情",
        fontSize = 15,
        fontWeight = "bold",
        fontColor = { 223, 239, 243, 255 },
    }

    local gearDetailsStatusLabel = UI.Label {
        text = "未连接动力",
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
    }

    local gearDetailsStatsLabel = UI.Label {
        text = "齿数  0\n层级  0 · 齿轮负载  0\n层负载  0 · 压速系数 x0\n整体轴转速  0 RPM\n轴上传入扭矩  0\n收益  不产生金币 · 仅负责传动",
        fontSize = 11,
        lineHeight = 1.35,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
        flexShrink = 1,
    }

    local gearDetailsUpgradeLabel = UI.Label {
        text = "Lv.1",
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
        flexShrink = 1,
    }

    local gearDetailsEssenceLabel = UI.Label {
        text = "永久精华  0 · 飞升 0 次",
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
        flexShrink = 1,
    }

    local gearUpgradeButton = UI.Button {
        text = "升级此齿轮",
        variant = "secondary",
        height = 38,
        width = "100%",
        fontSize = 11,
        fontWeight = "bold",
        textColor = { 78, 28, 110, 255 },
        backgroundColor = { 255, 255, 255, 255 },
        disabledBackgroundColor = { 103, 38, 147, 255 },
        hoverBackgroundColor = { 248, 231, 255, 255 },
        pressedBackgroundColor = { 225, 203, 236, 255 },
        borderColor = { 255, 255, 255, 255 },
        borderWidth = 2,
        borderRadius = 0,
        onClick = function()
            callbacks.upgradeSelectedGear()
        end,
    }

    local gearDetailsCloseButton = UI.Button {
        text = "关闭详情",
        variant = "secondary",
        height = 38,
        width = "100%",
        fontSize = 11,
        fontWeight = "bold",
        textColor = { 190, 224, 231, 255 },
        backgroundColor = { 67, 24, 99, 255 },
        hoverBackgroundColor = { 103, 38, 147, 255 },
        pressedBackgroundColor = { 45, 15, 68, 255 },
        borderColor = { 194, 112, 224, 255 },
        borderWidth = 2,
        borderRadius = 0,
        onClick = function()
            callbacks.closeGearDetails()
        end,
    }

    local gearDetailsCard = UI.Panel {
        width = 236,
        padding = 16,
        gap = 10,
        backgroundColor = { 18, 35, 47, 255 },
        backgroundGradient = {
            type = "linear",
            direction = 45,
            from = { 27, 76, 94, 255 },
            to = { 18, 35, 47, 255 },
        },
        borderColor = { 92, 210, 230, 255 },
        borderWidth = 2,
        borderRadius = 0,
        boxShadow = {
            { x = 6, y = 6, blur = 0, color = { 0, 0, 0, 90 } },
        },
        pointerEvents = "auto",
        children = {
            gearDetailsTitleLabel,
            gearDetailsStatusLabel,
            gearDetailsUpgradeLabel,
            gearUpgradeButton,
            UI.Button {
                id = "gearDeleteButton",
                text = "删除并回收",
                height = 38,
                width = "100%",
                fontSize = 11,
                fontWeight = "bold",
                textColor = { 255, 244, 235, 255 },
                backgroundColor = { 178, 42, 38, 255 },
                hoverBackgroundColor = { 220, 58, 48, 255 },
                pressedBackgroundColor = { 126, 25, 25, 255 },
                borderColor = { 255, 134, 105, 255 },
                borderWidth = 2,
                borderRadius = 0,
                onClick = function()
                    callbacks.deleteSelectedGear()
                end,
            },
            gearDetailsCloseButton,
        },
    }

    local gearDetailsPanel = UI.Panel {
        id = "gearDetailsPanel",
        visible = false,
        position = "absolute",
        top = 0,
        right = 0,
        bottom = 0,
        left = 0,
        alignItems = isLandscapeLayout and "center" or "flex-end",
        justifyContent = isLandscapeLayout and "center" or "flex-start",
        paddingTop = isLandscapeLayout and 0 or 82,
        paddingRight = isLandscapeLayout and 0 or 8,
        pointerEvents = "box-none",
        children = { gearDetailsCard },
    }

    local shopGearDetailsTitleLabel = UI.Label {
        text = "齿轮商品详情",
        fontSize = 15,
        fontWeight = "bold",
        textAlign = "left",
        fontColor = { 223, 239, 243, 255 },
    }

    local shopGearDetailsPriceLabel = UI.Label {
        text = "售价  ￥0",
        fontSize = 11,
        fontWeight = "bold",
        textAlign = "left",
        fontColor = { 190, 224, 231, 255 },
    }

    local shopGearDetailsDescriptionLabel = UI.Label {
        text = "齿轮详细介绍",
        fontSize = 11,
        lineHeight = 1.35,
        fontWeight = "bold",
        fontColor = { 190, 224, 231, 255 },
        flexShrink = 1,
    }

    local shopGearDetailsPanel
    local shopGearDetailsCloseButton = UI.Button {
        text = "关闭",
        variant = "secondary",
        height = 38,
        width = "100%",
        fontSize = 11,
        fontWeight = "bold",
        textColor = { 255, 241, 255, 255 },
        backgroundColor = { 103, 38, 147, 255 },
        hoverBackgroundColor = { 139, 53, 190, 255 },
        pressedBackgroundColor = { 67, 24, 99, 255 },
        borderColor = { 235, 155, 255, 255 },
        borderWidth = 2,
        borderRadius = 0,
        onClick = function()
            shopGearDetailsPanel:SetVisible(false)
        end,
    }

    local shopGearDetailsPanelProps = isLandscapeLayout
        and {
            top = "16%",
            bottom = "16%",
            left = "27%",
            right = "27%",
        }
        or {
            top = "24%",
            left = "10%",
            right = "10%",
        }
    shopGearDetailsPanelProps.id = "shopGearDetailsPanel"
    shopGearDetailsPanelProps.visible = false
    shopGearDetailsPanelProps.position = "absolute"
    shopGearDetailsPanelProps.padding = 16
    shopGearDetailsPanelProps.gap = 10
    shopGearDetailsPanelProps.backgroundColor = { 18, 35, 47, 255 }
    shopGearDetailsPanelProps.backgroundGradient = {
        type = "linear",
        direction = 45,
        from = { 27, 76, 94, 255 },
        to = { 18, 35, 47, 255 },
    }
    shopGearDetailsPanelProps.borderRadius = 0
    shopGearDetailsPanelProps.borderWidth = 2
    shopGearDetailsPanelProps.borderColor = { 92, 210, 230, 255 }
    shopGearDetailsPanelProps.boxShadow = {
        { x = 6, y = 6, blur = 0, color = { 0, 0, 0, 90 } },
    }
    shopGearDetailsPanelProps.pointerEvents = "auto"
    shopGearDetailsPanelProps.overflow = isLandscapeLayout
            and "hidden"
        or nil
    shopGearDetailsPanelProps.children = isLandscapeLayout
        and {
            UI.Panel {
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                height = 62,
                paddingLeft = 16,
                paddingRight = 16,
                justifyContent = "center",
                gap = 3,
                backgroundColor = { 67, 24, 99, 255 },
                borderBottomWidth = 1,
                borderBottomColor = { 225, 129, 255, 180 },
                pointerEvents = "none",
                children = {
                    shopGearDetailsTitleLabel,
                    shopGearDetailsPriceLabel,
                },
            },
            UI.ScrollView {
                position = "absolute",
                top = 62,
                right = 0,
                bottom = 58,
                left = 0,
                scrollY = true,
                showScrollbar = true,
                children = {
                    UI.Panel {
                        width = "100%",
                        paddingTop = 10,
                        paddingRight = 14,
                        paddingBottom = 10,
                        paddingLeft = 16,
                        children = {
                            shopGearDetailsDescriptionLabel,
                        },
                    },
                },
            },
            UI.Panel {
                position = "absolute",
                right = 16,
                bottom = 8,
                left = 16,
                height = 38,
                pointerEvents = "auto",
                children = { shopGearDetailsCloseButton },
            },
        }
        or {
            shopGearDetailsTitleLabel,
            shopGearDetailsPriceLabel,
            shopGearDetailsDescriptionLabel,
            shopGearDetailsCloseButton,
        }
    shopGearDetailsPanel = UI.Panel(shopGearDetailsPanelProps)

    local currencyGeneratorDetails = (function()
        local currencyGeneratorDetailsTitleLabel = UI.Label {
        text = "货币生成器",
        fontSize = isLandscapeLayout and 20 or 24,
        fontWeight = "bold",
        textAlign = "left",
        fontColor = { 255, 235, 165, 255 },
        flexGrow = 1,
        flexShrink = 1,
        pointerEvents = "none",
    }
    local currencyGeneratorDetailsStatusLabel = UI.Label {
        text = "当前状态",
        fontSize = isLandscapeLayout and 11 or 13,
        fontWeight = "bold",
        textAlign = "left",
        fontColor = { 111, 231, 255, 255 },
        whiteSpace = "normal",
        flexShrink = 0,
        pointerEvents = "none",
    }
    local currencyGeneratorDetailsHeader = UI.Panel {
        height = isLandscapeLayout and 104 or 116,
        minHeight = isLandscapeLayout and 104 or 116,
        flexShrink = 0,
        paddingTop = isLandscapeLayout and 12 or 15,
        paddingRight = isLandscapeLayout and 18 or 20,
        paddingBottom = isLandscapeLayout and 10 or 13,
        paddingLeft = isLandscapeLayout and 18 or 20,
        gap = isLandscapeLayout and 6 or 8,
        backgroundColor = { 15, 46, 66, 255 },
        backgroundGradient = {
            type = "linear",
            direction = 0,
            from = { 25, 83, 105, 255 },
            to = { 13, 37, 55, 255 },
        },
        borderBottomWidth = 4,
        borderBottomColor = { 247, 180, 62, 255 },
        pointerEvents = "none",
        children = {
            UI.Label {
                text = "FIXED MACHINE  /  机械设备",
                fontSize = isLandscapeLayout and 8 or 10,
                fontWeight = "bold",
                fontColor = { 104, 210, 232, 230 },
                letterSpacing = 1,
                pointerEvents = "none",
            },
            currencyGeneratorDetailsTitleLabel,
            currencyGeneratorDetailsStatusLabel,
        },
    }
    local currencyGeneratorDetailsDescriptionLabel = UI.Label {
        text = "固定机器功能说明",
        fontSize = isLandscapeLayout and 11 or 14,
        lineHeight = 1.55,
        whiteSpace = "normal",
        wordBreak = "break-word",
        fontColor = { 226, 239, 246, 255 },
        flexShrink = 1,
        width = "100%",
        pointerEvents = "none",
    }
    local currencyGeneratorDetailsPanel
    local currencyGeneratorDetailsPrimaryButton = UI.Button {
        text = "主要操作",
        variant = "primary",
        height = isLandscapeLayout and 44 or 48,
        minHeight = isLandscapeLayout and 44 or 48,
        width = isLandscapeLayout and nil or "100%",
        flexGrow = isLandscapeLayout and 1 or 0,
        flexBasis = isLandscapeLayout and 0 or nil,
        fontSize = isLandscapeLayout and 11 or 13,
        paddingLeft = 10,
        paddingRight = 10,
        alignSelf = "stretch",
        flexShrink = 0,
        visible = false,
        onClick = function()
            if callbacks.fixedMachinePrimaryAction then
                callbacks.fixedMachinePrimaryAction()
            end
        end,
    }
    local currencyGeneratorDetailsSecondaryButton = UI.Button {
        text = "次要操作",
        variant = "secondary",
        height = isLandscapeLayout and 44 or 48,
        minHeight = isLandscapeLayout and 44 or 48,
        width = isLandscapeLayout and nil or "100%",
        flexGrow = isLandscapeLayout and 1 or 0,
        flexBasis = isLandscapeLayout and 0 or nil,
        fontSize = isLandscapeLayout and 11 or 13,
        paddingLeft = 10,
        paddingRight = 10,
        alignSelf = "stretch",
        flexShrink = 0,
        visible = false,
        onClick = function()
            if callbacks.fixedMachineSecondaryAction then
                callbacks.fixedMachineSecondaryAction()
            end
        end,
    }
    local currencyGeneratorDetailsActionDock = UI.Panel {
        id = "currencyGeneratorDetailsActionDock",
        visible = false,
        width = isLandscapeLayout and "78%" or "100%",
        flexGrow = 0,
        flexDirection = isLandscapeLayout and "row" or "column",
        alignItems = "stretch",
        gap = isLandscapeLayout and 8 or 10,
        pointerEvents = "auto",
        children = {
            currencyGeneratorDetailsPrimaryButton,
            currencyGeneratorDetailsSecondaryButton,
        },
    }
    local currencyGeneratorDetailsCloseButton = UI.Button {
        text = "关闭",
        variant = "secondary",
        height = isLandscapeLayout and 44 or 46,
        minHeight = isLandscapeLayout and 44 or 46,
        width = "100%",
        flexGrow = 0,
        fontSize = isLandscapeLayout and 11 or 13,
        alignSelf = "stretch",
        flexShrink = 0,
        onClick = function()
            currencyGeneratorDetailsPanel:SetVisible(false)
        end,
    }
    local currencyGeneratorDetailsCloseDock = UI.Panel {
        width = isLandscapeLayout and "20%" or "100%",
        marginLeft = isLandscapeLayout and "2%" or 0,
        flexGrow = 0,
        alignItems = "stretch",
        pointerEvents = "auto",
        children = {
            currencyGeneratorDetailsCloseButton,
        },
    }
    local currencyGeneratorDetailsFooter = UI.Panel {
        width = "100%",
        paddingTop = isLandscapeLayout and 9 or 12,
        paddingRight = isLandscapeLayout and 14 or 18,
        paddingBottom = isLandscapeLayout and 10 or 16,
        paddingLeft = isLandscapeLayout and 14 or 18,
        flexDirection = isLandscapeLayout and "row" or "column",
        height = isLandscapeLayout and 64 or nil,
        minHeight = isLandscapeLayout and 64 or nil,
        flexShrink = 0,
        alignItems = "stretch",
        borderTopWidth = 2,
        borderTopColor = { 54, 125, 153, 180 },
        pointerEvents = "auto",
        children = {
            currencyGeneratorDetailsActionDock,
            currencyGeneratorDetailsCloseDock,
        },
    }
    local currencyGeneratorDetailsPanelProps = isLandscapeLayout
        and {
            top = "8%",
            bottom = "8%",
            left = "23%",
            right = "23%",
        }
        or {
            top = "10%",
            bottom = "10%",
            left = "8%",
            right = "8%",
        }
    currencyGeneratorDetailsPanelProps.id = "currencyGeneratorDetailsPanel"
    currencyGeneratorDetailsPanelProps.visible = false
    currencyGeneratorDetailsPanelProps.position = "absolute"
    currencyGeneratorDetailsPanelProps.padding = 0
    currencyGeneratorDetailsPanelProps.gap = 0
    currencyGeneratorDetailsPanelProps.backgroundColor = { 8, 20, 31, 254 }
    currencyGeneratorDetailsPanelProps.backgroundGradient = {
        type = "linear",
        direction = 45,
        from = { 18, 48, 63, 255 },
        to = { 8, 20, 31, 255 },
    }
    currencyGeneratorDetailsPanelProps.borderRadius = 0
    currencyGeneratorDetailsPanelProps.borderWidth = 3
    currencyGeneratorDetailsPanelProps.borderColor = { 8, 13, 22, 255 }
    currencyGeneratorDetailsPanelProps.boxShadow = HUD_SHADOW
    currencyGeneratorDetailsPanelProps.pointerEvents = "auto"
    currencyGeneratorDetailsPanelProps.overflow = "hidden"
    currencyGeneratorDetailsPanelProps.children = {
        currencyGeneratorDetailsHeader,
        UI.ScrollView {
            width = "100%",
            flexGrow = 1,
            flexBasis = 0,
            minHeight = 0,
            paddingTop = isLandscapeLayout and 14 or 18,
            paddingRight = isLandscapeLayout and 16 or 18,
            paddingBottom = isLandscapeLayout and 14 or 18,
            paddingLeft = isLandscapeLayout and 16 or 18,
            backgroundColor = { 16, 35, 48, 245 },
            scrollY = true,
            scrollX = false,
            showScrollbar = true,
            children = {
                UI.Panel {
                    width = "100%",
                    paddingTop = isLandscapeLayout and 12 or 14,
                    paddingRight = isLandscapeLayout and 14 or 16,
                    paddingBottom = isLandscapeLayout and 12 or 14,
                    paddingLeft = isLandscapeLayout and 14 or 16,
                    backgroundColor = { 11, 27, 39, 235 },
                    borderRadius = 0,
                    borderWidth = 1,
                    borderColor = { 66, 144, 166, 180 },
                    borderLeftWidth = 4,
                    borderLeftColor = { 247, 180, 62, 255 },
                    children = {
                        currencyGeneratorDetailsDescriptionLabel,
                    },
                },
            },
        },
        currencyGeneratorDetailsFooter,
    }
    currencyGeneratorDetailsPanel = UI.Panel(
        currencyGeneratorDetailsPanelProps
    )
    return {
            panel = currencyGeneratorDetailsPanel,
            titleLabel = currencyGeneratorDetailsTitleLabel,
            statusLabel = currencyGeneratorDetailsStatusLabel,
            descriptionLabel = currencyGeneratorDetailsDescriptionLabel,
            primaryButton = currencyGeneratorDetailsPrimaryButton,
            secondaryButton = currencyGeneratorDetailsSecondaryButton,
            actionDock = currencyGeneratorDetailsActionDock,
        }
    end)()

    local globalUpgradeSummaryLabel = UI.Label {
        text = "全局加成",
        fontSize = 13,
        lineHeight = 1.4,
        fontColor = { 216, 224, 238, 255 },
    }

    local globalIncomeUpgradeButton = UI.Button {
        text = "升级全收益",
        variant = "primary",
        height = 42,
        alignSelf = "stretch",
        onClick = function()
            callbacks.upgradeGlobal("income")
        end,
    }

    local decayUpgradeButton = UI.Button {
        text = "降低传动损耗",
        variant = "secondary",
        height = 42,
        alignSelf = "stretch",
        onClick = function()
            callbacks.upgradeGlobal("decay")
        end,
    }

    local offlineUpgradeButton = UI.Button {
        text = "提升离线倍率",
        variant = "secondary",
        height = 42,
        alignSelf = "stretch",
        onClick = function()
            callbacks.upgradeGlobal("offline")
        end,
    }

    local unlockBuildingButton = UI.Button {
        text = "解锁永久建筑",
        variant = "secondary",
        height = 42,
        alignSelf = "stretch",
        onClick = function()
            callbacks.purchaseMetaUnlock(
                "buildings",
                "precisionFoundry"
            )
        end,
    }

    ---@type Widget
    local globalUpgradePanel
    local globalUpgradeCloseButton = UI.Button {
        text = "关闭",
        variant = "secondary",
        height = 36,
        alignSelf = "stretch",
        onClick = function()
            globalUpgradePanel:SetVisible(false)
        end,
    }

    local globalUpgradeTitleLabel = UI.Label {
        text = "全局工坊升级",
        fontSize = 18,
        fontWeight = "bold",
        fontColor = { 255, 225, 132, 255 },
    }
    local globalUpgradeDescriptionLabel = UI.Label {
        text = "永久强化对所有轮回生效，消耗齿轮精华",
        fontSize = 11,
        fontColor = { 160, 177, 202, 235 },
    }
    local globalUpgradePrimaryRow = UI.Panel {
        flexDirection = isLandscapeLayout and "row" or "column",
        gap = isLandscapeLayout and 6 or 9,
        pointerEvents = "auto",
        children = {
            globalIncomeUpgradeButton,
            decayUpgradeButton,
            offlineUpgradeButton,
        },
    }
    local globalUpgradeUnlockRow = UI.Panel {
        flexDirection = isLandscapeLayout and "row" or "column",
        gap = isLandscapeLayout and 6 or 9,
        pointerEvents = "auto",
        children = {
            unlockBuildingButton,
        },
    }
    local globalUpgradeCloseRow = UI.Panel {
        alignItems = "center",
        pointerEvents = "auto",
        children = { globalUpgradeCloseButton },
    }
    local globalUpgradePanelProps = isLandscapeLayout
        and {
            top = "17%",
            bottom = "17%",
            left = "27%",
            right = "27%",
        }
        or {
            top = "12%",
            left = "8%",
            right = "8%",
            height = 520,
        }
    globalUpgradePanelProps.visible = false
    globalUpgradePanelProps.position = "absolute"
    globalUpgradePanelProps.padding = 16
    globalUpgradePanelProps.gap = 9
    globalUpgradePanelProps.backgroundColor = { 24, 30, 43, 252 }
    globalUpgradePanelProps.borderRadius = 0
    globalUpgradePanelProps.borderWidth = 2
    globalUpgradePanelProps.borderColor = { 111, 211, 167, 180 }
    globalUpgradePanelProps.pointerEvents = "auto"
    globalUpgradePanelProps.children = {
        globalUpgradeTitleLabel,
        globalUpgradeDescriptionLabel,
        globalUpgradeSummaryLabel,
        globalUpgradePrimaryRow,
        globalUpgradeUnlockRow,
        globalUpgradeCloseRow,
    }
    globalUpgradePanel = UI.Panel(globalUpgradePanelProps)

    local permanentUpgradeRevealed_ = false
    local permanentUpgradeTitleLabel = UI.Label {
        text = "永久强化",
        visible = isLandscapeLayout,
        position = "absolute",
        height = 13,
        minHeight = 13,
        fontSize = 8,
        lineHeight = 1,
        fontWeight = "bold",
        fontColor = { 226, 239, 243, 255 },
        textAlign = "center",
        whiteSpace = "nowrap",
        pointerEvents = "none",
    }
    local permanentUpgradeLevelLabel = UI.Label {
        text = "Lv.0",
        visible = isLandscapeLayout,
        position = "absolute",
        height = 13,
        minHeight = 13,
        fontSize = 8,
        lineHeight = 1,
        fontWeight = "bold",
        fontColor = { 216, 239, 245, 255 },
        textAlign = "center",
        whiteSpace = "nowrap",
        pointerEvents = "none",
    }
    local permanentUpgradePriceLabel = UI.Label {
        text = "￥200",
        visible = isLandscapeLayout,
        position = "absolute",
        height = 13,
        minHeight = 13,
        fontSize = 8,
        lineHeight = 1,
        fontWeight = "bold",
        fontColor = { 255, 203, 92, 255 },
        textAlign = "left",
        whiteSpace = "nowrap",
        pointerEvents = "none",
    }
    local permanentUpgradeActionLabel = UI.Label {
        text = "升级",
        visible = isLandscapeLayout,
        position = "absolute",
        width = 54,
        height = 30,
        minHeight = 30,
        paddingTop = 7,
        fontSize = 9,
        fontWeight = "bold",
        fontColor = { 255, 225, 151, 255 },
        textAlign = "center",
        backgroundColor = { 84, 56, 17, 250 },
        borderWidth = 1,
        borderColor = { 245, 187, 69, 245 },
        borderRadius = 0,
        pointerEvents = "none",
    }
    local globalUpgradeOpenButton = UI.Button {
        text = isLandscapeLayout and "" or "永久强化",
        variant = "primary",
        width = 64,
        height = 38,
        flexGrow = 1,
        flexBasis = 0,
        fontSize = 11,
        onClick = function()
            callbacks.openGlobalUpgradePanel()
        end,
    }

    local ascensionOpenButton = UI.Button {
        id = "ascensionOpenButton",
        text = "飞升重构",
        variant = "secondary",
        width = 64,
        height = 38,
        flexGrow = 1,
        flexBasis = 0,
        fontSize = 11,
        paddingLeft = 28,
        paddingRight = 4,
        textAlign = "left",
        onClick = function()
            print("[GameUI] 点击飞升入口: portrait")
            callbacks.openAscensionPanel()
        end,
        children = {
            ImageIcon {
                position = "absolute",
                left = 3,
                top = 5,
                width = 28,
                height = 28,
                imagePath = ASCENSION_ICON_PATH,
            },
        },
    }

    local homeReturnButton = UI.Button {
        id = "homeReturnButton",
        text = "",
        visible = isLandscapeLayout,
        variant = "standard",
        width = 42,
        height = 42,
        padding = 0,
        backgroundColor = { 0, 0, 0, 0 },
        hoverBackgroundColor = { 0, 0, 0, 0 },
        pressedBackgroundColor = { 0, 0, 0, 0 },
        borderColor = { 0, 0, 0, 0 },
        borderWidth = 0,
        boxShadow = false,
        onClick = function()
            if callbacks.returnHome then
                callbacks.returnHome()
            end
        end,
        children = {
            ImageIcon {
                position = "absolute",
                left = 3,
                top = 3,
                width = 32,
                height = 32,
                imagePath = HOME_HUD_ICON_PATH,
            },
        },
    }

    local landscapeAscensionButton = UI.Button {
        id = "landscapeAscensionButton",
        text = "飞升",
        visible = isLandscapeLayout,
        variant = "secondary",
        position = "absolute",
        top = 8,
        right = 0,
        width = 84,
        height = 34,
        fontSize = 10,
        fontWeight = "bold",
        paddingLeft = 28,
        paddingRight = 4,
        textAlign = "left",
        onClick = function()
            print("[GameUI] 点击飞升入口: landscape")
            callbacks.openAscensionPanel()
        end,
        children = {
            ImageIcon {
                position = "absolute",
                left = 3,
                top = 3,
                width = 28,
                height = 28,
                imagePath = ASCENSION_ICON_PATH,
            },
        },
    }

    local essenceOpenButton = UI.Button {
        text = "强化",
        variant = "secondary",
        height = 28,
        paddingLeft = 7,
        paddingRight = 7,
        flexShrink = 0,
        fontSize = 10,
        onClick = function()
            callbacks.openGlobalUpgradePanel()
        end,
    }

    local ascensionRewardLabel = UI.Label {
        text = "本次预计获得 0 齿轮精华",
        fontSize = 16,
        fontWeight = "bold",
        textAlign = "center",
        fontColor = { 130, 208, 255, 255 },
    }

    local ascensionProgressLabel = UI.Label {
        text = "本局累计 ￥0",
        fontSize = 12,
        lineHeight = 1.4,
        textAlign = "center",
        fontColor = { 218, 226, 239, 245 },
    }

    ---@type Widget
    local ascensionPanel
    local ascensionConfirmButton = UI.Button {
        text = "确认飞升",
        variant = "primary",
        height = 46,
        flexGrow = 1,
        onClick = function()
            callbacks.requestAscension()
        end,
    }
    local ascensionCloseButton = UI.Button {
        text = "暂不飞升",
        variant = "secondary",
        height = 46,
        flexGrow = 1,
        onClick = function()
            ascensionPanel:SetVisible(false)
        end,
    }
    local ascensionTitleLabel = UI.Label {
        text = "飞升重构",
        fontSize = 20,
        fontWeight = "bold",
        textAlign = "center",
        fontColor = { 255, 226, 139, 255 },
    }
    local ascensionDescriptionLabel = UI.Label {
        text = "飞升作用：重置本轮工坊，按本局实际赚取的资金兑换永久齿轮精华（每￥1000 = 1精华）。\n精华用途：永久提高全部收益、降低传动损耗、增强离线收益，还可解锁废铜矿区与巨型齿轮工厂。\n将清空：本局资金、摆放齿轮、主齿轮临时等级、单齿轮等级、自动驱动。\n永久保留：齿轮精华、精华强化、飞升次数、子地图与建筑权限。",
        fontSize = 11,
        lineHeight = 1.4,
        textAlign = "left",
        fontColor = { 184, 196, 215, 245 },
    }
    local ascensionActionRow = UI.Panel {
        flexDirection = "row",
        gap = 8,
        children = {
            ascensionCloseButton,
            ascensionConfirmButton,
        },
    }
    local ascensionPanelProps = isLandscapeLayout
        and {
            top = "17%",
            bottom = "17%",
            left = "28%",
            right = "28%",
        }
        or {
            top = "23%",
            left = "8%",
            right = "8%",
        }
    ascensionPanelProps.visible = false
    ascensionPanelProps.position = "absolute"
    ascensionPanelProps.padding = 18
    ascensionPanelProps.gap = 11
    ascensionPanelProps.backgroundColor = { 23, 30, 45, 253 }
    ascensionPanelProps.borderRadius = 0
    ascensionPanelProps.borderWidth = 2
    ascensionPanelProps.borderColor = { 116, 205, 255, 210 }
    ascensionPanelProps.pointerEvents = "auto"
    ascensionPanelProps.overflow = isLandscapeLayout
            and "hidden"
        or nil
    ascensionPanelProps.children = isLandscapeLayout
        and {
            UI.Panel {
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                height = 58,
                paddingLeft = 12,
                paddingRight = 12,
                justifyContent = "center",
                alignItems = "center",
                gap = 3,
                pointerEvents = "none",
                children = {
                    ascensionTitleLabel,
                    ascensionRewardLabel,
                },
            },
            UI.ScrollView {
                position = "absolute",
                top = 58,
                right = 0,
                bottom = 54,
                left = 0,
                scrollX = false,
                scrollY = true,
                showScrollbar = true,
                children = {
                    UI.Panel {
                        width = "100%",
                        paddingTop = 6,
                        paddingRight = 14,
                        paddingBottom = 10,
                        paddingLeft = 12,
                        gap = 7,
                        children = {
                            ascensionProgressLabel,
                            ascensionDescriptionLabel,
                        },
                    },
                },
            },
            UI.Panel {
                position = "absolute",
                left = 12,
                right = 12,
                bottom = 8,
                height = 38,
                pointerEvents = "auto",
                children = { ascensionActionRow },
            },
        }
        or {
            ascensionTitleLabel,
            ascensionRewardLabel,
            ascensionProgressLabel,
            ascensionDescriptionLabel,
            ascensionActionRow,
        }
    ascensionPanel = UI.Panel(ascensionPanelProps)

    local ascensionToastLabel = UI.Label {
        text = "",
        visible = false,
        position = "absolute",
        top = "32%",
        left = "8%",
        right = "8%",
        padding = 14,
        borderRadius = 0,
        backgroundColor = { 27, 68, 77, 242 },
        borderWidth = 2,
        borderColor = { 124, 230, 211, 220 },
        textAlign = "center",
        fontSize = 15,
        fontWeight = "bold",
        fontColor = { 217, 255, 246, 255 },
        pointerEvents = "none",
    }

    local offlineRewardLabel = UI.Label {
        text = "离线收益",
        fontSize = 16,
        lineHeight = 1.4,
        textAlign = "center",
        fontColor = { 255, 229, 145, 255 },
    }

    local claimOfflineButton = UI.Button {
        text = "领取离线收益",
        variant = "success",
        height = 44,
        alignSelf = "stretch",
        onClick = function()
            callbacks.claimOfflineReward()
        end,
    }

    local offlineRewardPanel = UI.Panel {
        visible = false,
        position = "absolute",
        top = "34%",
        left = "12%",
        right = "12%",
        height = 220,
        padding = 18,
        gap = 12,
        backgroundColor = { 28, 34, 48, 253 },
        borderRadius = 0,
        borderWidth = 2,
        borderColor = { 255, 205, 89, 210 },
        pointerEvents = "auto",
        children = {
            UI.Label {
                text = "欢迎回到齿轮工坊",
                fontSize = 18,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = { 235, 240, 250, 255 },
            },
            offlineRewardLabel,
            claimOfflineButton,
        },
    }

    local recycleDropZone = UI.Panel {
        id = "recycleDropZone",
        visible = false,
        position = "absolute",
        left = isLandscapeLayout and "33%" or "12%",
        right = isLandscapeLayout and "33%" or "12%",
        bottom = isLandscapeLayout and 16 or 24,
        height = isLandscapeLayout and 72 or 82,
        flexDirection = "row",
        justifyContent = "center",
        alignItems = "center",
        gap = 12,
        paddingHorizontal = 16,
        backgroundColor = { 176, 36, 39, 238 },
        borderWidth = 3,
        borderColor = { 255, 129, 102, 255 },
        borderRadius = 10,
        boxShadow = {
            { x = 0, y = 5, blur = 12, color = { 0, 0, 0, 145 } },
        },
        pointerEvents = "none",
        children = {
            UI.Panel {
                width = 36,
                height = 42,
                flexShrink = 0,
                position = "relative",
                pointerEvents = "none",
                children = {
                    UI.Panel {
                        position = "absolute",
                        left = 7,
                        top = 7,
                        width = 22,
                        height = 5,
                        backgroundColor = { 255, 239, 214, 255 },
                        borderRadius = 2,
                        pointerEvents = "none",
                    },
                    UI.Panel {
                        position = "absolute",
                        left = 12,
                        top = 2,
                        width = 12,
                        height = 5,
                        backgroundColor = { 255, 239, 214, 255 },
                        borderRadius = 2,
                        pointerEvents = "none",
                    },
                    UI.Panel {
                        position = "absolute",
                        left = 9,
                        top = 14,
                        width = 18,
                        height = 24,
                        backgroundColor = { 255, 239, 214, 255 },
                        borderRadius = 3,
                        pointerEvents = "none",
                    },
                },
            },
            UI.Panel {
                flexShrink = 1,
                minWidth = 0,
                gap = 2,
                pointerEvents = "none",
                children = {
                    UI.Label {
                        text = "拖到这里回收",
                        fontSize = isLandscapeLayout and 17 or 18,
                        fontWeight = "bold",
                        fontColor = { 255, 250, 240, 255 },
                        pointerEvents = "none",
                    },
                    UI.Label {
                        id = "recycleRefundLabel",
                        text = "松开返还金币",
                        fontSize = isLandscapeLayout and 11 or 12,
                        fontColor = { 255, 216, 166, 255 },
                        pointerEvents = "none",
                    },
                },
            },
        },
    }

    local canvasInputArea = UI.Panel {
        id = "canvasInputArea",
        position = "absolute",
        top = 0,
        left = 0,
        right = 0,
        bottom = 0,
        backgroundColor = { 0, 0, 0, 0 },
        pointerEvents = "auto",
        onPointerDown = callbacks.canvasPointerDown,
        onPointerMove = callbacks.canvasPointerMove,
        onPointerUp = callbacks.canvasPointerUp,
        onPointerCancel = callbacks.canvasPointerCancel,
    }

    local basicShopPanel = UI.Panel {
        flexDirection = "row",
        gap = 7,
        pointerEvents = "auto",
        children = {
            buySmallGearButton,
            buyMediumGearButton,
            buyLargeGearButton,
            buyCompoundGearButton,
        },
    }

    local transmissionShopPanel = UI.Panel {
        visible = false,
        flexDirection = "row",
        gap = 7,
        pointerEvents = "auto",
        children = {
            buyMommaGearButton,
            buyLubricantGearButton,
            buyCoinGearButton,
        },
    }

    local factoryShopPanel = UI.Panel {
        visible = false,
        padding = 8,
        gap = 6,
        borderRadius = 0,
        borderWidth = 1,
        borderColor = { 74, 150, 118, 190 },
        backgroundColor = { 19, 42, 39, 242 },
        pointerEvents = "auto",
        children = {
            factoryStatusLabel,
            factoryClaimButton,
        },
    }

    local permanentUpgradeFrame = StretchImage {
        visible = false,
        position = "absolute",
        imagePath = SIDE_RAIL_IMAGE_PATHS.upgradeCard,
    }
    local permanentUpgradeIcon = ImageIcon {
        position = "absolute",
        width = 38,
        height = 38,
        imagePath = HUD_B_ICON_PATHS.permanent,
    }
    local permanentLockedQuestionIcon = ImageIcon {
        visible = false,
        position = "absolute",
        width = 38,
        height = 38,
        imagePath = LOCKED_QUESTION_ICON_PATH,
    }
    local mainUpgradeRow = UI.Panel {
        position = isLandscapeLayout and "relative" or nil,
        flexDirection = "row",
        gap = 6,
        pointerEvents = "auto",
        children = isLandscapeLayout
                and {
                    mainTorqueUpgradeButton,
                    mainCircleIncomeUpgradeButton,
                    clickUpgradeWrapper,
                    globalUpgradeOpenButton,
                    permanentUpgradeFrame,
                    permanentUpgradeIcon,
                    permanentLockedQuestionIcon,
                    permanentUpgradeTitleLabel,
                    permanentUpgradeLevelLabel,
                    permanentUpgradePriceLabel,
                    permanentUpgradeActionLabel,
                }
            or {
                mainTorqueUpgradeButton,
                mainCircleIncomeUpgradeButton,
                clickUpgradeWrapper,
            },
    }
    local globalActionRow = UI.Panel {
        flexDirection = "row",
        gap = 7,
        pointerEvents = "auto",
        children = isLandscapeLayout
                and {}
            or {
                globalUpgradeOpenButton,
                ascensionOpenButton,
            },
    }
    local mainGearShopPanel = UI.Panel {
        visible = false,
        gap = 6,
        pointerEvents = "auto",
        children = {
            autoDriveButton,
            levelLabel,
            mainUpgradeRow,
        },
    }
    local upgradeShopPanel = UI.Panel {
        visible = false,
        gap = 7,
        pointerEvents = "auto",
        children = {
            UI.Label {
                text = "永久成长与轮回重构",
                visible = not isLandscapeLayout,
                fontSize = 11,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = { 184, 207, 232, 245 },
                pointerEvents = "none",
            },
            globalActionRow,
        },
    }

    local shopTabs = {
        basic = basicShopPanel,
        transmission = transmissionShopPanel,
        factory = factoryShopPanel,
        mainGear = mainGearShopPanel,
        upgrade = upgradeShopPanel,
    }
    local shopTabButtons = {}
    local shopCategoryOrder = { "basic", "transmission", "factory" }
    local shopCategoryNames = {
        basic = "基础",
        transmission = "特殊",
        factory = "工厂",
    }
    local activeShopTab = "basic"
    local shopExpanded = false
    local landscapeDialExpanded = false
    local gearWarehouseUnlocked_ = false
    local upgradeRailUnlocked_ = false
    local currentLeftRailWidth = 160
    local currentRightRailWidth = 200
    local landscapeCategoryButton
    local upgradeRegion
    local shopDrawer
    local leftRailExpandButton
    local rightRailExpandButton
    local leftRailCollapseHandle
    local rightRailCollapseHandle
    local ApplyLeftRailState
    local ApplyRightRailState
    ---@type Widget
    local shopBody
    ---@type Button
    local shopToggleButton
    ---@type Widget
    local shopToggleDock

    local function SetShopTab(tabId)
        if isLandscapeLayout
            and (tabId == "mainGear" or tabId == "upgrade") then
            tabId = "basic"
        end
        activeShopTab = tabId
        for id, panel in pairs(shopTabs) do
            local alwaysVisibleInLandscape = isLandscapeLayout
                and id == "mainGear"
            panel:SetVisible(alwaysVisibleInLandscape or id == tabId)
        end
        if landscapeCategoryButton and shopCategoryNames[tabId] then
            landscapeCategoryButton:SetText(shopCategoryNames[tabId] .. "  >")
        end
        if upgradeRegion then
            upgradeRegion:SetVisible(isLandscapeLayout)
        end
        for id, button in pairs(shopTabButtons) do
            local selected = id == tabId
            if isLandscapeLayout then
                button:SetStyle({
                    variant = selected and "primary" or "secondary",
                })
                button:SetOpacity(selected and 1 or 0.72)
            else
                local accent = id == "mainGear"
                        and { 247, 180, 62, 255 }
                    or id == "upgrade"
                        and { 213, 100, 255, 255 }
                    or { 76, 205, 238, 255 }
                local selectedBackground = id == "mainGear"
                        and { 88, 57, 18, 255 }
                    or id == "upgrade"
                        and { 75, 35, 101, 255 }
                    or { 24, 76, 105, 255 }
                button:SetStyle({
                    backgroundColor = selected
                        and selectedBackground
                        or { 20, 29, 43, 255 },
                    hoverBackgroundColor = selected
                        and selectedBackground
                        or { 31, 48, 68, 255 },
                    pressedBackgroundColor = { 12, 20, 31, 255 },
                    borderWidth = selected and 2 or 1,
                    borderColor = selected
                        and accent
                        or { 65, 86, 112, 220 },
                    borderRadius = 0,
                    textColor = selected
                        and { 255, 255, 255, 255 }
                        or { 176, 194, 216, 255 },
                    fontWeight = "bold",
                    boxShadow = selected
                        and {
                            {
                                x = 2,
                                y = 2,
                                blur = 0,
                                color = { 0, 0, 0, 85 },
                            },
                        }
                        or false,
                    pressedBoxShadow = false,
                })
                button:SetOpacity(1)
            end
        end
    end

    local function CreateShopTabButton(tabId, text)
        local button = UI.Button {
            text = text,
            variant = tabId == activeShopTab and "primary" or "secondary",
            height = 34,
            width = 0,
            flexGrow = 1,
            flexBasis = 0,
            flexShrink = 1,
            minWidth = 0,
            fontSize = 10,
            paddingLeft = 3,
            paddingRight = 3,
            onClick = function()
                SetShopTab(tabId)
            end,
        }
        shopTabButtons[tabId] = button
        return button
    end

    local basicTabButton = CreateShopTabButton("basic", "基础")
    local transmissionTabButton = CreateShopTabButton("transmission", "特殊")
    local factoryTabButton = CreateShopTabButton("factory", "特殊")
    local mainGearTabButton = CreateShopTabButton("mainGear", "主齿轮")
    local upgradeTabButton = CreateShopTabButton("upgrade", "强化")

    local shopTabRow = UI.Panel {
        flexDirection = "row",
        gap = 4,
        pointerEvents = "auto",
        children = {
            basicTabButton,
            transmissionTabButton,
            factoryTabButton,
            mainGearTabButton,
            upgradeTabButton,
        },
    }

    landscapeCategoryButton = UI.Button {
        text = "基础  >",
        visible = false,
        variant = "primary",
        width = 64,
        height = 26,
        alignSelf = "stretch",
        fontSize = 9,
        paddingLeft = 2,
        paddingRight = 2,
        onClick = function()
            local currentIndex = 1
            for index, categoryId in ipairs(shopCategoryOrder) do
                if categoryId == activeShopTab then
                    currentIndex = index
                    break
                end
            end
            SetShopTab(
                shopCategoryOrder[
                    currentIndex % #shopCategoryOrder + 1
                ]
            )
        end,
    }

    local function SetShopExpanded(expanded)
        if isLandscapeLayout then
            shopExpanded = true
            shopBody:SetVisible(true)
            shopToggleDock:SetVisible(false)
            if upgradeRegion then
                upgradeRegion:SetVisible(true)
            end
            return
        end
        shopExpanded = expanded
        shopBody:SetVisible(expanded)
        if upgradeRegion then
            upgradeRegion:SetVisible(isLandscapeLayout)
        end
        shopToggleButton:SetText(expanded and "收起商店  ▼" or "展开商店  ▲")
        shopToggleDock:SetStyle({
            bottom = expanded and 305 or 68,
        })
    end

    shopToggleButton = UI.Button {
        text = "展开商店  ▲",
        variant = "secondary",
        height = 34,
        minWidth = 132,
        flexShrink = 0,
        fontSize = 11,
        paddingLeft = 14,
        paddingRight = 14,
        onClick = function()
            SetShopExpanded(not shopExpanded)
        end,
    }

    shopToggleDock = UI.Panel {
        position = "absolute",
        left = 0,
        right = 0,
        bottom = 68,
        alignItems = "center",
        pointerEvents = "box-none",
        children = { shopToggleButton },
    }

    shopBody = UI.Panel {
        visible = false,
        height = 220,
        flexShrink = 0,
        gap = 7,
        pointerEvents = "auto",
        children = isLandscapeLayout
            and {
                shopTabRow,
                landscapeCategoryButton,
                basicShopPanel,
                transmissionShopPanel,
                factoryShopPanel,
            }
            or {
                shopTabRow,
                landscapeCategoryButton,
                basicShopPanel,
                transmissionShopPanel,
                factoryShopPanel,
                mainGearShopPanel,
                upgradeShopPanel,
            },
    }

    local shopTitleLabel = UI.Label {
        text = "齿轮商店",
        fontSize = 13,
        fontWeight = "bold",
        fontColor = { 255, 220, 127, 255 },
        flexShrink = 0,
    }

    local leftRailCollapseButton
    local rightRailCollapseButton
    if isLandscapeLayout then
        leftRailCollapseButton = UI.Button {
            text = "<",
            width = 28,
            height = 26,
            minWidth = 28,
            flexShrink = 0,
            fontSize = 11,
            fontWeight = "bold",
            backgroundColor = { 58, 42, 19, 255 },
            hoverBackgroundColor = { 92, 65, 24, 255 },
            pressedBackgroundColor = { 35, 25, 12, 255 },
            borderWidth = { 1, 3, 3, 1 },
            borderColor = { 226, 174, 74, 245 },
            borderRadius = 0,
            onClick = function()
                landscapeLeftRailCollapsed_ = true
                ApplyLeftRailState(true)
            end,
        }
        rightRailCollapseButton = UI.Button {
            text = ">",
            width = 28,
            height = 26,
            minWidth = 28,
            flexShrink = 0,
            fontSize = 11,
            fontWeight = "bold",
            backgroundColor = { 18, 53, 62, 255 },
            hoverBackgroundColor = { 27, 82, 96, 255 },
            pressedBackgroundColor = { 11, 33, 39, 255 },
            borderWidth = { 1, 1, 3, 3 },
            borderColor = { 88, 218, 238, 245 },
            borderRadius = 0,
            onClick = function()
                landscapeRightRailCollapsed_ = true
                ApplyRightRailState(true)
            end,
        }
    end

    local leftPanelFrame = UI.Panel {
        visible = false,
        position = "absolute",
        top = 0,
        left = 0,
        right = 0,
        bottom = 0,
        backgroundImage = SIDE_RAIL_IMAGE_PATHS.leftPanel,
        backgroundFit = "sliced",
        backgroundSlice = { 32, 32, 32, 32 },
        pointerEvents = "none",
    }
    local blueprintTrayBackdrop = BlueprintTrayBackdrop {
        visible = isLandscapeLayout,
        position = "absolute",
        top = 0,
        left = 0,
        right = 0,
        bottom = 0,
    }
    local leftRailHeader = UI.Panel {
        height = 42,
        flexShrink = 0,
        flexDirection = "row",
        alignItems = "center",
        justifyContent = "center",
        pointerEvents = "box-none",
        children = {
            shopTitleLabel,
        },
    }
    local shopDrawerProps = {
        position = "absolute",
        padding = 6,
        gap = 4,
        backgroundColor = { 6, 28, 43, 218 },
        borderRadius = 8,
        borderWidth = 1,
        borderColor = { 65, 214, 237, 175 },
        boxShadow = {
            { x = 0, y = 0, blur = 10, color = { 35, 195, 225, 38 } },
        },
        pointerEvents = "auto",
        translateX = 0,
        opacity = 1,
        transition = "translateX 0.24s easeOutCubic, opacity 0.18s easeOut",
        children = {
            leftPanelFrame,
            blueprintTrayBackdrop,
            leftRailHeader,
            shopBody,
        },
    }
    if isLandscapeLayout then
        shopDrawerProps.top = 4
        shopDrawerProps.left = 0
    else
        shopDrawerProps.left = 16
        shopDrawerProps.right = 16
        shopDrawerProps.bottom = 18
    end
    shopDrawer = UI.Panel(shopDrawerProps)

    local upgradeTitleLabel = UI.Label {
        text = "齿轮升级",
        fontSize = 13,
        fontWeight = "bold",
        fontColor = { 132, 231, 245, 255 },
    }

    local modifyCoreIcon = ImageIcon {
        position = "absolute",
        width = 48,
        height = 48,
        imagePath = HUD_B_ICON_PATHS.modify,
    }
    local modifyCoreLabel = UI.Label {
        text = "改装\n▼",
        position = "absolute",
        width = 76,
        fontSize = 14,
        lineHeight = 1,
        fontWeight = "bold",
        fontColor = { 255, 205, 91, 255 },
        textAlign = "center",
        pointerEvents = "none",
    }
    local upgradeDialBackdrop = UpgradeDialBackdrop {
        position = "absolute",
        top = 0,
        left = 0,
        right = 0,
        bottom = 0,
        expanded = false,
    }
    local upgradeDialContent = UI.Panel {
        visible = false,
        position = "absolute",
        top = 0,
        left = 0,
        right = 0,
        bottom = 0,
        zIndex = 4,
        pointerEvents = "box-none",
        children = {
            mainGearShopPanel,
            upgradeShopPanel,
        },
    }
    local SetLandscapeDialExpanded
    local modifyCoreButton = UI.Button {
        text = "",
        position = "absolute",
        width = 132,
        height = 132,
        zIndex = 12,
        backgroundColor = { 0, 0, 0, 0 },
        hoverBackgroundColor = { 255, 197, 63, 20 },
        pressedBackgroundColor = { 255, 197, 63, 36 },
        borderWidth = 0,
        boxShadow = false,
        onClick = function()
            SetLandscapeDialExpanded(not landscapeDialExpanded)
        end,
    }
    local rightPanelFrame = UI.Panel {
        visible = false,
        position = "absolute",
        top = 0,
        left = 0,
        right = 0,
        bottom = 0,
        backgroundImage = SIDE_RAIL_IMAGE_PATHS.rightPanel,
        backgroundFit = "sliced",
        backgroundSlice = { 32, 32, 32, 32 },
        pointerEvents = "none",
    }
    local rightRailHeader = UI.Panel {
        position = "absolute",
        top = 4,
        left = 4,
        right = 4,
        height = 42,
        flexDirection = "row",
        alignItems = "center",
        justifyContent = "center",
        pointerEvents = "box-none",
        children = {
            upgradeTitleLabel,
        },
    }
    local upgradeRegionProps = {
        visible = false,
        position = "absolute",
        width = 300,
        height = 300,
        padding = 0,
        gap = 0,
        backgroundColor = { 0, 0, 0, 0 },
        borderWidth = 0,
        pointerEvents = "box-none",
        translateX = 0,
        opacity = 1,
        transition = "translateX 0.24s easeOutCubic, opacity 0.18s easeOut",
        children = isLandscapeLayout
            and {
                rightPanelFrame,
                upgradeDialBackdrop,
                rightRailHeader,
                upgradeDialContent,
                modifyCoreButton,
                modifyCoreIcon,
                modifyCoreLabel,
            }
            or {},
    }
    if isLandscapeLayout then
        upgradeRegionProps.top = 4
        upgradeRegionProps.right = 0
    else
        upgradeRegionProps.left = 16
        upgradeRegionProps.right = 16
        upgradeRegionProps.bottom = 28
    end
    upgradeRegion = UI.Panel(upgradeRegionProps)

    leftRailCollapseHandle = UI.Card {
        visible = isLandscapeLayout and not landscapeLeftRailCollapsed_,
        position = "absolute",
        width = 44,
        height = 80,
        zIndex = 31,
        clickable = true,
        hoverable = true,
        padding = 0,
        backgroundColor = { 0, 0, 0, 0 },
        hoverBackgroundColor = { 32, 218, 244, 18 },
        pressedBackgroundColor = { 32, 218, 244, 34 },
        borderWidth = 0,
        borderRadius = 0,
        boxShadow = false,
        onClick = function()
            landscapeLeftRailCollapsed_ = true
            ApplyLeftRailState(true)
        end,
        children = {
            UI.Panel {
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                bottom = 0,
                backgroundImage = SIDE_RAIL_IMAGE_PATHS.leftHandle,
                backgroundFit = "contain",
                pointerEvents = "none",
            },
            DirectionTriangle {
                direction = "left",
                position = "absolute",
                top = 0,
                left = 4,
                right = 1,
                bottom = 0,
            },
        },
    }

    rightRailCollapseHandle = UI.Card {
        visible = isLandscapeLayout and not landscapeRightRailCollapsed_,
        position = "absolute",
        width = 44,
        height = 80,
        zIndex = 31,
        clickable = true,
        hoverable = true,
        padding = 0,
        backgroundColor = { 0, 0, 0, 0 },
        hoverBackgroundColor = { 32, 218, 244, 18 },
        pressedBackgroundColor = { 32, 218, 244, 34 },
        borderWidth = 0,
        borderRadius = 0,
        boxShadow = false,
        onClick = function()
            landscapeRightRailCollapsed_ = true
            ApplyRightRailState(true)
        end,
        children = {
            UI.Panel {
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                bottom = 0,
                backgroundImage = SIDE_RAIL_IMAGE_PATHS.rightHandle,
                backgroundFit = "contain",
                pointerEvents = "none",
            },
            DirectionTriangle {
                direction = "right",
                position = "absolute",
                top = 0,
                left = 1,
                right = 4,
                bottom = 0,
            },
        },
    }

    SetLandscapeDialExpanded = function(expanded)
        landscapeDialExpanded = expanded == true
        upgradeDialBackdrop:SetExpanded(landscapeDialExpanded)
        upgradeDialContent:SetVisible(landscapeDialExpanded)
        permanentUpgradeIcon:SetVisible(
            landscapeDialExpanded and permanentUpgradeRevealed_
        )
        permanentLockedQuestionIcon:SetVisible(
            landscapeDialExpanded and not permanentUpgradeRevealed_
        )
        permanentUpgradeTitleLabel:SetVisible(landscapeDialExpanded)
        permanentUpgradeLevelLabel:SetVisible(landscapeDialExpanded)
        modifyCoreLabel:SetText(
            landscapeDialExpanded and "改装\n▲" or "改装\n▼"
        )
        if not landscapeDialExpanded then
            HideMainUpgradeDetails()
        end
    end
    SetLandscapeDialExpanded(false)

    leftRailExpandButton = UI.Card {
        visible = isLandscapeLayout and landscapeLeftRailCollapsed_,
        position = "absolute",
        left = 0,
        top = 240,
        width = 48,
        height = 206,
        zIndex = 30,
        clickable = true,
        hoverable = true,
        padding = 5,
        gap = 5,
        flexDirection = "column",
        alignItems = "center",
        justifyContent = "center",
        backgroundColor = { 3, 29, 45, 248 },
        hoverBackgroundColor = { 8, 57, 75, 255 },
        borderWidth = { 2, 3, 3, 0 },
        borderColor = { 76, 226, 246, 245 },
        borderRadius = 0,
        boxShadow = {
            { x = 0, y = 0, blur = 10, color = { 35, 218, 245, 52 } },
        },
        onClick = function()
            landscapeLeftRailCollapsed_ = false
            ApplyLeftRailState(true)
        end,
        children = {
            GearIcon {
                width = 30,
                height = 30,
                gearType = "small",
            },
            UI.Label {
                text = "齿\n轮\n仓\n库",
                fontSize = 10,
                lineHeight = 1.05,
                fontWeight = "bold",
                fontColor = { 255, 218, 121, 255 },
                textAlign = "center",
                pointerEvents = "none",
            },
            DirectionTriangle {
                direction = "right",
                width = 22,
                height = 22,
            },
        },
    }

    rightRailExpandButton = UI.Card {
        visible = isLandscapeLayout and landscapeRightRailCollapsed_,
        position = "absolute",
        right = 0,
        top = 340,
        width = 48,
        height = 206,
        zIndex = 30,
        clickable = true,
        hoverable = true,
        padding = 5,
        gap = 5,
        flexDirection = "column",
        alignItems = "center",
        justifyContent = "center",
        backgroundColor = { 3, 29, 45, 248 },
        hoverBackgroundColor = { 8, 57, 75, 255 },
        borderWidth = { 2, 0, 3, 3 },
        borderColor = { 76, 226, 246, 245 },
        borderRadius = 0,
        boxShadow = {
            { x = 0, y = 0, blur = 10, color = { 35, 218, 245, 52 } },
        },
        onClick = function()
            landscapeRightRailCollapsed_ = false
            ApplyRightRailState(true)
            if callbacks.tutorialNotify then
                callbacks.tutorialNotify("upgrade_opened")
            end
        end,
        children = {
            ImageIcon {
                width = 30,
                height = 30,
                imagePath = HUD_B_ICON_PATHS.modify,
            },
            UI.Label {
                text = "动\n力\n改\n装",
                fontSize = 10,
                lineHeight = 1.05,
                fontWeight = "bold",
                fontColor = { 255, 218, 121, 255 },
                textAlign = "center",
                pointerEvents = "none",
            },
            DirectionTriangle {
                direction = "left",
                width = 22,
                height = 22,
            },
        },
    }

    ApplyLeftRailState = function(animated)
        if not isLandscapeLayout then
            leftRailExpandButton:SetVisible(false)
            leftRailCollapseHandle:SetVisible(false)
            return
        end
        if not animated then
            shopDrawer:StopAnimation()
        end
        leftPanelFrame:SetVisible(true)
        blueprintTrayBackdrop:SetVisible(false)
        shopDrawer:SetStyle({
            translateX = landscapeLeftRailCollapsed_
                    and -(currentLeftRailWidth + 28)
                or 0,
            opacity = landscapeLeftRailCollapsed_ and 0 or 1,
            pointerEvents = landscapeLeftRailCollapsed_ and "none" or "auto",
        })
        leftRailExpandButton:SetVisible(
            gearWarehouseUnlocked_ and landscapeLeftRailCollapsed_
        )
        leftRailCollapseHandle:SetVisible(
            gearWarehouseUnlocked_ and not landscapeLeftRailCollapsed_
        )
    end

    ApplyRightRailState = function(animated)
        if not isLandscapeLayout then
            rightRailExpandButton:SetVisible(false)
            rightRailCollapseHandle:SetVisible(false)
            return
        end
        if not animated then
            upgradeRegion:StopAnimation()
        end
        upgradeRegion:SetStyle({
            translateX = landscapeRightRailCollapsed_
                    and (currentRightRailWidth + 28)
                or 0,
            opacity = landscapeRightRailCollapsed_ and 0 or 1,
            pointerEvents = landscapeRightRailCollapsed_ and "none" or "auto",
        })
        rightRailExpandButton:SetVisible(
            upgradeRailUnlocked_ and landscapeRightRailCollapsed_
        )
        rightRailCollapseHandle:SetVisible(
            upgradeRailUnlocked_ and not landscapeRightRailCollapsed_
        )
    end

    local titleLabel = UI.Label {
        text = callbacks.title,
        fontSize = 10,
        fontWeight = "bold",
        fontColor = { 173, 183, 204, 220 },
    }

    local currencyStatusPanel = UI.Card {
        flexGrow = 1,
        flexShrink = 1,
        minWidth = 0,
        flexDirection = "row",
        alignItems = "center",
        gap = 7,
        paddingHorizontal = 8,
        paddingVertical = 4,
        backgroundColor = { 23, 31, 37, 252 },
        borderColor = { 211, 159, 53, 240 },
        pointerEvents = "none",
        children = {
            ImageIcon {
                imagePath = COIN_ICON_PATH,
                width = 34,
                height = 34,
            },
            UI.Panel {
                flexGrow = 1,
                flexShrink = 1,
                minWidth = 0,
                gap = 1,
                pointerEvents = "none",
                children = {
                    titleLabel,
                    coinLabel,
                    clickValueLabel,
                },
            },
        },
    }

    local productionStatusPanel = UI.Card {
        flexGrow = 1,
        flexShrink = 1,
        minWidth = 0,
        flexDirection = "row",
        alignItems = "center",
        gap = 7,
        paddingHorizontal = 8,
        paddingVertical = 4,
        backgroundColor = { 16, 35, 43, 252 },
        borderColor = { 52, 179, 207, 235 },
        pointerEvents = "auto",
        children = {
            ImageIcon {
                imagePath = ESSENCE_ICON_PATH,
                width = 32,
                height = 32,
            },
            UI.Panel {
                flexGrow = 1,
                flexShrink = 1,
                minWidth = 0,
                alignItems = "flex-end",
                gap = 1,
                pointerEvents = "auto",
                children = {
                    revenueLabel,
                    essenceLabel,
                    essenceOpenButton,
                },
            },
        },
    }

    local topStatusRow = UI.Panel {
        flexDirection = "row",
        alignItems = "stretch",
        gap = 6,
        pointerEvents = "auto",
        children = {
            currencyStatusPanel,
            productionStatusPanel,
            idleEarningsButton,
            layoutToggleButton,
        },
    }

    local loadStatusRow = UI.Card {
        flexDirection = "row",
        alignItems = "center",
        gap = 8,
        minHeight = 32,
        paddingHorizontal = 8,
        paddingVertical = 4,
        backgroundColor = { 7, 15, 20, 252 },
        borderColor = { 76, 128, 143, 235 },
        pointerEvents = "box-none",
        children = {
            homeReturnButton,
            UI.Panel {
                flexGrow = 1,
                flexShrink = 1,
                minWidth = 80,
                children = { loadProgressBar },
            },
            loadGaugeLabel,
        },
    }

    local topHudFrame = StretchImage {
        visible = false,
        position = "absolute",
        top = 0,
        left = 0,
        right = 0,
        height = 72,
        imagePath = SIDE_RAIL_IMAGE_PATHS.topHud,
    }
    local topStatusBar = UI.Panel {
        position = "absolute",
        top = 10,
        left = 12,
        right = 12,
        gap = 7,
        backgroundColor = { 0, 0, 0, 0 },
        pointerEvents = "box-none",
        children = {
            topStatusRow,
            powerStatusLabel,
            loadStatusRow,
        },
    }

    local root = UI.Panel {
        id = "gameUI",
        width = callbacks.layoutWidth or "100%",
        height = callbacks.layoutHeight or "100%",
        position = callbacks.rotatePortrait and "absolute" or nil,
        left = callbacks.rotatePortrait and 0 or nil,
        top = callbacks.rotatePortrait and 0 or nil,
        rotate = callbacks.rotatePortrait and -90 or nil,
        translateX = callbacks.rotatePortrait
                and ((callbacks.layoutHeight - callbacks.layoutWidth) * 0.5)
            or nil,
        translateY = callbacks.rotatePortrait
                and ((callbacks.layoutHeight - callbacks.layoutWidth) * 0.5)
            or nil,
        transformOrigin = "center",
        pointerEvents = "box-none",
        children = {
            canvasInputArea,
            UI.SafeAreaView {
                width = "100%",
                height = "100%",
                nativeMenuInset = true,
                pointerEvents = "box-none",
                children = {
                    topHudFrame,
                    topStatusBar,
                    shopDrawer,
                    upgradeRegion,
                    leftRailCollapseHandle,
                    rightRailCollapseHandle,
                    leftRailExpandButton,
                    rightRailExpandButton,
                    shopToggleDock,
                    landscapeAscensionButton,
                },
            },
            recycleDropZone,
            gearDetailsPanel,
            shopGearDetailsPanel,
            currencyGeneratorDetails.panel,
            globalUpgradePanel,
            offlineRewardPanel,
            ascensionPanel,
            ascensionToastLabel,
            clickUpgradeDetailsPanel,
        },
    }

    local function ApplyLandscapeSideRailLayout(options)
        local function Clamp(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end

        local screenWidth = options.width
        local screenHeight = options.height
        local safeMargin = Clamp(screenWidth * 0.01, 8, 16)

        -- 头部 HUD 统一从左右边界向中间分配空间，避免各控件使用
        -- 独立魔数后在窄逻辑分辨率下互相覆盖。
        local topSidePadding = safeMargin
        local primaryHudHeight = Clamp(screenHeight * 0.095, 58, 76)
        local currencyWidth = Clamp(screenWidth * 0.14, 128, 190)
        local productionWidth = Clamp(screenWidth * 0.15, 145, 200)
        local ascensionWidth = Clamp(screenWidth * 0.066, 76, 90)
        local idleWidth = Clamp(screenWidth * 0.075, 76, 92)
        local layoutWidth = Clamp(screenWidth * 0.055, 64, 76)
        local actionGap = Clamp(screenWidth * 0.006, 5, 8)
        local centerGap = Clamp(screenWidth * 0.01, 8, 14)

        local currencyLeft = topSidePadding + 8
        local actionGroupRight = screenWidth - topSidePadding
        local ascensionLeft = actionGroupRight - ascensionWidth
        local idleLeft = ascensionLeft - actionGap - idleWidth
        local layoutLeft = idleLeft - actionGap - layoutWidth
        -- 竖屏切换按钮当前隐藏，不再让它挤占头部背景的可用分段。
        local actionGroupLeft = idleLeft
        local productionRight = actionGroupLeft - centerGap
        local productionLeft = productionRight - productionWidth
        local centerLeft = currencyLeft + currencyWidth + centerGap
        local centerRight = productionLeft - centerGap
        local availableCenterWidth = math.max(0, centerRight - centerLeft)
        local minimumInlineLoadWidth = Clamp(screenWidth * 0.25, 260, 320)
        local useSecondLoadRow = availableCenterWidth < minimumInlineLoadWidth
        local secondLoadRowHeight = useSecondLoadRow
                and Clamp(primaryHudHeight * 0.78, 46, 54)
            or 0
        local topHudHeight = primaryHudHeight + secondLoadRowHeight
        local railTop = topHudHeight + safeMargin
        local railBottom = safeMargin
        local availableRailHeight = math.max(
            240,
            screenHeight - railTop - railBottom
        )

        local leftWidth = Clamp(screenWidth * 0.205, 230, 286)
        local leftHeight = availableRailHeight
        local rightWidth = Clamp(screenWidth * 0.255, 282, 342)
        local rightHeight = math.min(
            availableRailHeight,
            Clamp(screenHeight * 0.55, 300, 420)
        )
        local rightTop = screenHeight - railBottom - rightHeight

        local leftInset = Clamp(leftWidth * 0.048, 10, 15)
        local rightInset = Clamp(rightWidth * 0.075, 18, 28)
        local headerHeight = Clamp(leftHeight * 0.07, 38, 46)
        local tabHeight = Clamp(leftHeight * 0.052, 28, 34)
        local sectionGap = Clamp(leftHeight * 0.015, 7, 11)

        currentLeftRailWidth = leftWidth
        currentRightRailWidth = rightWidth

        shopTitleLabel:SetText("齿轮仓库")
        shopTitleLabel:SetVisible(true)
        shopTitleLabel:SetStyle({
            position = "absolute",
            top = 0,
            left = 0,
            width = leftWidth - leftInset * 2,
            height = headerHeight,
            fontSize = Clamp(leftWidth * 0.057, 13, 16),
            textAlign = "center",
            fontWeight = "bold",
            fontColor = { 255, 220, 127, 255 },
        })
        leftRailCollapseButton:SetVisible(false)
        leftRailHeader:SetStyle({
            position = "absolute",
            top = leftInset * 0.35,
            left = leftInset,
            right = leftInset,
            height = headerHeight,
            minHeight = headerHeight,
            alignItems = "center",
            justifyContent = "center",
        })
        shopInfoLabel:SetVisible(false)
        shopDrawer:SetStyle({
            top = railTop,
            left = safeMargin,
            width = leftWidth,
            height = leftHeight,
            maxHeight = leftHeight,
            overflow = "hidden",
            padding = 0,
            gap = 0,
            backgroundColor = { 0, 0, 0, 0 },
            borderWidth = 0,
            borderColor = { 0, 0, 0, 0 },
            borderRadius = 0,
            boxShadow = {
                { x = 0, y = 0, blur = 12, color = { 31, 218, 244, 48 } },
            },
        })

        local shopBodyTop = headerHeight + leftInset
        local shopBodyHeight = leftHeight - shopBodyTop - leftInset
        local shopBodyWidth = leftWidth - leftInset * 2
        shopBody:SetStyle({
            position = "absolute",
            top = shopBodyTop,
            left = leftInset,
            width = shopBodyWidth,
            height = shopBodyHeight,
            maxHeight = shopBodyHeight,
            flexGrow = 0,
            flexShrink = 0,
            gap = sectionGap,
            overflow = "hidden",
        })
        shopTabRow:SetVisible(true)
        shopTabRow:SetStyle({
            position = "absolute",
            top = 0,
            left = 0,
            width = math.max(1, shopBodyWidth - 1),
            height = tabHeight,
            gap = Clamp(shopBodyWidth * 0.012, 2, 4),
        })
        basicTabButton:SetText("基础")
        transmissionTabButton:SetText("特殊")
        factoryTabButton:SetText("工厂")
        landscapeCategoryButton:SetVisible(false)
        mainGearTabButton:SetVisible(false)
        upgradeTabButton:SetVisible(false)
        for _, button in ipairs({
            basicTabButton,
            transmissionTabButton,
            factoryTabButton,
        }) do
            button:SetStyle({
                height = tabHeight,
                minWidth = 0,
                flexGrow = 1,
                flexBasis = 0,
                fontSize = Clamp(tabHeight * 0.31, 8, 10),
                paddingLeft = 3,
                paddingRight = 3,
                borderRadius = 0,
            })
        end

        local cardPanelTop = tabHeight + sectionGap
        local cardPanelHeight = math.max(
            120,
            shopBodyHeight - cardPanelTop
        )
        local cardGap = Clamp(cardPanelHeight * 0.022, 7, 12)
        local shopCardHeight = math.max(
            54,
            (cardPanelHeight - cardGap * 3) / 4
        )
        local cardPanelWidth = shopBodyWidth
        for _, panel in ipairs({
            basicShopPanel,
            transmissionShopPanel,
        }) do
            panel:SetStyle({
                position = "absolute",
                top = cardPanelTop,
                left = 0,
                width = cardPanelWidth,
                height = cardPanelHeight,
                flexDirection = "column",
                alignItems = "stretch",
                gap = cardGap,
                overflow = "hidden",
            })
        end
        factoryShopPanel:SetStyle({
            position = "absolute",
            top = cardPanelTop,
            left = 0,
            width = cardPanelWidth,
            height = cardPanelHeight,
            overflow = "hidden",
        })

        for _, card in ipairs({
            buySmallGearButton,
            buyMediumGearButton,
            buyLargeGearButton,
            buyCompoundGearButton,
            buyMommaGearButton,
            buyLubricantGearButton,
            buyCoinGearButton,
        }) do
            local iconSize = Clamp(
                math.min(shopCardHeight * 0.64, cardPanelWidth * 0.28),
                36,
                72
            )
            local contentOffset = 10
            local iconLeft = Clamp(cardPanelWidth * 0.04, 16, 22)
            local iconTop = (shopCardHeight - iconSize) * 0.5
            local textLeft = math.max(
                cardPanelWidth * 0.43 + contentOffset,
                iconLeft + iconSize + 8
            )
            local lockedActionRight = Clamp(
                cardPanelWidth * 0.025,
                6,
                9
            )
            local lockedActionWidth = Clamp(
                cardPanelWidth * 0.25,
                56,
                70
            )
            local textRightReserve = lockedActionWidth
                + lockedActionRight
                + 8
            local textWidth = math.max(
                50,
                cardPanelWidth - textLeft - textRightReserve
            )
            local badgeSize = Clamp(shopCardHeight * 0.2, 17, 23)

            card:SetStyle({
                width = "100%",
                minWidth = 0,
                height = shopCardHeight,
                minHeight = shopCardHeight,
                flexGrow = 0,
                flexShrink = 0,
                flexBasis = shopCardHeight,
                padding = 0,
                gap = 0,
                flexDirection = "row",
                alignItems = "center",
                backgroundColor = { 5, 34, 51, 220 },
                hoverBackgroundColor = { 10, 58, 77, 238 },
                borderWidth = 0,
                borderColor = { 0, 0, 0, 0 },
                borderRadius = 0,
                boxShadow = false,
            })
            card.props.frameImage:SetVisible(true)
            card.props.infoPanel:SetStyle({
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                bottom = 0,
                padding = 0,
                gap = 0,
            })
            card.props.layoutCardHeight = shopCardHeight
            card.props.lockedStatusLabel:SetStyle({
                position = "absolute",
                top = shopCardHeight * 0.42,
                left = textLeft,
                width = textWidth,
                height = shopCardHeight * 0.2,
                fontSize = Clamp(shopCardHeight * 0.095, 8, 10),
                textAlign = "left",
                whiteSpace = "nowrap",
            })
            card.props.lockedActionLabel:SetStyle({
                position = "absolute",
                top = (shopCardHeight - 28) * 0.5,
                right = lockedActionRight,
                width = lockedActionWidth,
                height = 28,
                minHeight = 28,
                paddingTop = 6,
            })
            card.props.slotLabel:SetVisible(
                card.props.revealed ~= false
                    and card.props.hasSlotNumber
            )
            card.props.slotLabel:SetStyle({
                position = "absolute",
                top = 3,
                left = 6,
                right = nil,
                width = badgeSize,
                height = badgeSize,
                fontSize = Clamp(badgeSize * 0.42, 7, 9),
                textAlign = "center",
            })
            card.props.countLabel:SetVisible(
                card.props.revealed ~= false
                    and card.props.hasSlotNumber
            )
            card.props.countLabel:SetStyle({
                position = "absolute",
                bottom = 6,
                right = 7,
                width = badgeSize,
                height = badgeSize,
                fontSize = Clamp(badgeSize * 0.45, 8, 10),
                textAlign = "center",
            })
            card.props.gearIconSlot:SetStyle({
                position = "absolute",
                left = iconLeft,
                top = iconTop,
                width = iconSize,
                minWidth = iconSize,
                height = iconSize,
                minHeight = iconSize,
            })
            card.props.gearImage:SetStyle({
                width = iconSize * 0.82,
                height = iconSize * 0.82,
            })
            card.props.lockedQuestionIcon:SetStyle({
                position = "absolute",
                left = iconSize * 0.09,
                top = iconSize * 0.09,
                width = iconSize * 0.82,
                height = iconSize * 0.82,
            })
            card.props.modelLabel:SetStyle({
                position = "absolute",
                left = textLeft,
                top = shopCardHeight
                    * (card.props.revealed == false and 0.15 or 0.27),
                width = textWidth,
                height = shopCardHeight * 0.22,
                fontSize = Clamp(shopCardHeight * 0.095, 8, 11),
                textAlign = "left",
                whiteSpace = "nowrap",
            })
            card.props.priceLabel:SetStyle({
                position = "absolute",
                left = textLeft,
                top = shopCardHeight
                    * (card.props.revealed == false and 0.68 or 0.57),
                width = textWidth,
                height = shopCardHeight
                    * (card.props.revealed == false and 0.2 or 0.22),
                fontSize = Clamp(shopCardHeight * 0.105, 9, 12),
                textAlign = "left",
                whiteSpace = "nowrap",
            })
        end

        local rightHeaderHeight = Clamp(rightHeight * 0.125, 40, 52)
        upgradeTitleLabel:SetText("动力改装")
        upgradeTitleLabel:SetVisible(true)
        upgradeTitleLabel:SetStyle({
            position = "absolute",
            top = 0,
            left = 0,
            width = rightWidth - rightInset * 2,
            height = rightHeaderHeight,
            fontSize = Clamp(rightWidth * 0.047, 13, 16),
            textAlign = "center",
            fontWeight = "bold",
            fontColor = { 255, 220, 127, 255 },
        })
        rightRailCollapseButton:SetVisible(false)
        rightRailHeader:SetStyle({
            top = rightInset * 0.25,
            left = rightInset,
            right = rightInset,
            height = rightHeaderHeight,
            zIndex = 8,
            alignItems = "center",
            justifyContent = "center",
        })
        rightPanelFrame:SetVisible(true)
        upgradeRegion:SetStyle({
            top = rightTop,
            right = safeMargin,
            width = rightWidth,
            height = rightHeight,
            maxHeight = rightHeight,
            overflow = "hidden",
            padding = 0,
            gap = 0,
            pointerEvents = "auto",
            backgroundColor = { 0, 0, 0, 0 },
            borderWidth = 0,
            borderColor = { 0, 0, 0, 0 },
            borderRadius = 0,
            boxShadow = {
                { x = 0, y = 0, blur = 12, color = { 31, 218, 244, 48 } },
            },
        })
        upgradeRegion:SetVisible(true)
        upgradeDialBackdrop:SetVisible(false)
        modifyCoreButton:SetVisible(false)
        modifyCoreIcon:SetVisible(false)
        modifyCoreLabel:SetVisible(false)
        permanentUpgradeIcon:SetVisible(permanentUpgradeRevealed_)
        permanentLockedQuestionIcon:SetVisible(
            not permanentUpgradeRevealed_
        )
        permanentUpgradeTitleLabel:SetVisible(true)
        permanentUpgradeLevelLabel:SetVisible(true)
        permanentUpgradePriceLabel:SetVisible(true)
        upgradeDialContent:SetVisible(true)
        mainGearShopPanel:SetVisible(true)
        upgradeShopPanel:SetVisible(false)

        local upgradeContentTop = rightHeaderHeight
        local upgradeContentHeight = rightHeight
            - upgradeContentTop
            - rightInset * 0.7
        local upgradeCardGap = Clamp(upgradeContentHeight * 0.022, 6, 10)
        local upgradeCardHeight = math.max(
            48,
            (upgradeContentHeight - upgradeCardGap * 3) / 4
        )
        local upgradeCardWidth = rightWidth - rightInset * 2

        mainGearShopPanel:SetStyle({
            position = "absolute",
            top = upgradeContentTop,
            left = rightInset,
            width = upgradeCardWidth,
            height = upgradeContentHeight,
            overflow = "hidden",
            gap = 0,
        })
        mainUpgradeRow:SetStyle({
            position = "absolute",
            top = 0,
            left = 0,
            width = upgradeCardWidth,
            height = upgradeContentHeight,
            flexDirection = "column",
            alignItems = "stretch",
            justifyContent = "flex-start",
            gap = upgradeCardGap,
            overflow = "hidden",
        })

        local upgradeCards = {
            mainTorqueUpgradeButton,
            mainCircleIncomeUpgradeButton,
            upgradeButton,
        }
        for index, button in ipairs(upgradeCards) do
            local cardTop = (index - 1)
                * (upgradeCardHeight + upgradeCardGap)
            local iconCellWidth = Clamp(
                upgradeCardWidth * 0.28,
                58,
                78
            )
            local iconSize = math.min(
                iconCellWidth * 0.68,
                upgradeCardHeight * 0.64
            )
            local textLeft = iconCellWidth + Clamp(
                upgradeCardWidth * 0.035,
                8,
                12
            )
            local actionWidth = Clamp(
                upgradeCardWidth * 0.25,
                56,
                70
            )
            local actionHeight = Clamp(
                upgradeCardHeight * 0.39,
                24,
                31
            )
            local textWidth = math.max(
                54,
                upgradeCardWidth - textLeft - actionWidth - 14
            )

            button:SetStyle({
                position = "absolute",
                top = cardTop,
                left = 0,
                width = upgradeCardWidth,
                minWidth = upgradeCardWidth,
                height = upgradeCardHeight,
                minHeight = upgradeCardHeight,
                flexGrow = 0,
                flexShrink = 0,
                flexBasis = upgradeCardHeight,
                padding = 0,
                backgroundColor = { 5, 34, 51, 225 },
                hoverBackgroundColor = { 10, 61, 81, 242 },
                pressedBackgroundColor = { 3, 27, 42, 250 },
                borderWidth = 0,
                borderColor = { 0, 0, 0, 0 },
                borderRadius = 0,
                boxShadow = false,
            })
            button.props.frameImage:SetVisible(true)
            button.props.gearImage:SetStyle({
                position = "absolute",
                top = (upgradeCardHeight - iconSize) * 0.5,
                left = (iconCellWidth - iconSize) * 0.5,
                width = iconSize,
                height = iconSize,
                backgroundFit = "contain",
            })
            button.props.lockedQuestionIcon:SetStyle({
                position = "absolute",
                top = (upgradeCardHeight - iconSize) * 0.5,
                left = (iconCellWidth - iconSize) * 0.5,
                width = iconSize,
                height = iconSize,
                backgroundFit = "contain",
            })
            button.props.modelLabel:SetStyle({
                position = "absolute",
                top = upgradeCardHeight * 0.15,
                left = textLeft,
                width = textWidth,
                height = upgradeCardHeight * 0.22,
                minHeight = 14,
                fontSize = Clamp(upgradeCardHeight * 0.13, 8, 11),
                textAlign = "left",
                whiteSpace = "nowrap",
            })
            button.props.effectLabel:SetVisible(true)
            button.props.effectLabel:SetStyle({
                position = "absolute",
                top = upgradeCardHeight * 0.42,
                left = textLeft,
                width = textWidth,
                height = upgradeCardHeight * 0.2,
                minHeight = 13,
                fontSize = Clamp(upgradeCardHeight * 0.115, 8, 10),
                textAlign = "left",
                whiteSpace = "nowrap",
                fontColor = { 83, 225, 245, 255 },
            })
            button.props.priceLabel:SetVisible(true)
            button.props.priceLabel:SetStyle({
                position = "absolute",
                top = upgradeCardHeight * 0.68,
                left = textLeft,
                width = textWidth,
                height = upgradeCardHeight * 0.2,
                minHeight = 13,
                fontSize = Clamp(upgradeCardHeight * 0.12, 8, 10),
                textAlign = "left",
                whiteSpace = "nowrap",
            })
            button.props.actionLabel:SetVisible(true)
            button.props.actionLabel:SetStyle({
                position = "absolute",
                top = (upgradeCardHeight - actionHeight) * 0.5,
                right = Clamp(upgradeCardWidth * 0.025, 6, 9),
                width = actionWidth,
                height = actionHeight,
                minHeight = actionHeight,
                paddingTop = math.max(5, actionHeight * 0.22),
                borderRadius = 0,
            })
        end

        clickUpgradeWrapper:SetStyle({
            position = "absolute",
            top = (upgradeCardHeight + upgradeCardGap) * 2,
            left = 0,
            width = upgradeCardWidth,
            minWidth = upgradeCardWidth,
            height = upgradeCardHeight,
            minHeight = upgradeCardHeight,
            overflow = "visible",
        })
        upgradeButton:SetStyle({ top = 0, left = 0 })

        local permanentTop = (upgradeCardHeight + upgradeCardGap) * 3
        local permanentIconCellWidth = Clamp(
            upgradeCardWidth * 0.28,
            58,
            78
        )
        local permanentIconSize = math.min(
            permanentIconCellWidth * 0.68,
            upgradeCardHeight * 0.64
        )
        local permanentTextLeft = permanentIconCellWidth
            + Clamp(upgradeCardWidth * 0.035, 8, 12)
        local permanentActionWidth = Clamp(
            upgradeCardWidth * 0.25,
            56,
            70
        )
        local permanentActionHeight = Clamp(
            upgradeCardHeight * 0.39,
            24,
            31
        )
        local permanentTextWidth = math.max(
            54,
            upgradeCardWidth
                - permanentTextLeft
                - permanentActionWidth
                - 14
        )

        globalUpgradeOpenButton:SetStyle({
            position = "absolute",
            top = permanentTop,
            left = 0,
            width = upgradeCardWidth,
            minWidth = upgradeCardWidth,
            maxWidth = upgradeCardWidth,
            height = upgradeCardHeight,
            minHeight = upgradeCardHeight,
            flexGrow = 0,
            flexShrink = 0,
            backgroundColor = { 5, 34, 51, 225 },
            hoverBackgroundColor = { 10, 61, 81, 242 },
            pressedBackgroundColor = { 3, 27, 42, 250 },
            borderWidth = 0,
            borderColor = { 0, 0, 0, 0 },
            borderRadius = 0,
            boxShadow = false,
        })
        permanentUpgradeFrame:SetVisible(true)
        permanentUpgradeFrame:SetStyle({
            position = "absolute",
            top = permanentTop,
            left = 0,
            width = upgradeCardWidth,
            height = upgradeCardHeight,
        })
        permanentUpgradeIcon:SetStyle({
            position = "absolute",
            top = permanentTop
                + (upgradeCardHeight - permanentIconSize) * 0.5,
            left = (permanentIconCellWidth - permanentIconSize) * 0.5,
            width = permanentIconSize,
            height = permanentIconSize,
        })
        permanentLockedQuestionIcon:SetStyle({
            position = "absolute",
            top = permanentTop
                + (upgradeCardHeight - permanentIconSize) * 0.5,
            left = (permanentIconCellWidth - permanentIconSize) * 0.5,
            width = permanentIconSize,
            height = permanentIconSize,
        })
        permanentUpgradeTitleLabel:SetStyle({
            position = "absolute",
            top = permanentTop + upgradeCardHeight * 0.15,
            left = permanentTextLeft,
            width = permanentTextWidth,
            height = upgradeCardHeight * 0.22,
            minHeight = 14,
            fontSize = Clamp(upgradeCardHeight * 0.13, 8, 11),
            textAlign = "left",
        })
        permanentUpgradeLevelLabel:SetStyle({
            position = "absolute",
            top = permanentTop + upgradeCardHeight * 0.42,
            left = permanentTextLeft,
            width = permanentTextWidth,
            height = upgradeCardHeight * 0.2,
            minHeight = 13,
            fontSize = Clamp(upgradeCardHeight * 0.115, 8, 10),
            textAlign = "left",
            fontColor = { 83, 225, 245, 255 },
        })
        permanentUpgradePriceLabel:SetStyle({
            position = "absolute",
            top = permanentTop + upgradeCardHeight * 0.68,
            left = permanentTextLeft,
            width = permanentTextWidth,
            height = upgradeCardHeight * 0.2,
            minHeight = 13,
            fontSize = Clamp(upgradeCardHeight * 0.12, 8, 10),
            textAlign = "left",
        })
        permanentUpgradeActionLabel:SetVisible(true)
        permanentUpgradeActionLabel:SetStyle({
            position = "absolute",
            top = permanentTop
                + (upgradeCardHeight - permanentActionHeight) * 0.5,
            right = Clamp(upgradeCardWidth * 0.025, 6, 9),
            width = permanentActionWidth,
            height = permanentActionHeight,
            minHeight = permanentActionHeight,
            paddingTop = math.max(5, permanentActionHeight * 0.22),
            borderRadius = 0,
        })

        local leftHandleWidth = Clamp(leftWidth * 0.18, 40, 50)
        local handleHeight = Clamp(leftHeight * 0.19, 86, 122)
        local rightHandleWidth = Clamp(rightWidth * 0.14, 40, 48)
        leftRailCollapseHandle:SetStyle({
            left = safeMargin + leftWidth - leftHandleWidth * 0.15,
            top = railTop + (leftHeight - handleHeight) * 0.5,
            width = leftHandleWidth,
            height = handleHeight,
        })
        rightRailCollapseHandle:SetStyle({
            right = safeMargin + rightWidth - rightHandleWidth * 0.08,
            top = rightTop + (rightHeight - handleHeight) * 0.5,
            width = rightHandleWidth,
            height = handleHeight,
        })
        leftRailExpandButton:SetStyle({
            top = railTop + (leftHeight - 206) * 0.5,
        })
        rightRailExpandButton:SetStyle({
            top = rightTop + (rightHeight - 206) * 0.5,
        })

        local topButtonHeight = Clamp(primaryHudHeight * 0.46, 28, 34)
        local preferredLoadWidth = Clamp(screenWidth * 0.44, 300, 640)
        local loadWidth
        local loadLeft
        if useSecondLoadRow then
            loadWidth = math.min(
                Clamp(screenWidth * 0.72, 430, 640),
                screenWidth - topSidePadding * 2 - 24
            )
            loadLeft = (screenWidth - loadWidth) * 0.5
        else
            loadWidth = math.min(preferredLoadWidth, availableCenterWidth)
            local centeredLoadLeft = centerLeft
                + (availableCenterWidth - loadWidth) * 0.5
            local loadRightShift = Clamp(screenWidth * 0.02, 14, 28)
            loadLeft = math.min(
                centeredLoadLeft + loadRightShift,
                centerRight - loadWidth
            )
        end

        topHudFrame:SetVisible(true)
        topHudFrame:SetStyle({
            top = 0,
            left = 0,
            right = 0,
            height = topHudHeight,
        })
        topStatusBar:SetStyle({
            top = 0,
            left = 0,
            right = 0,
            height = topHudHeight,
            padding = 0,
            gap = 0,
            backgroundColor = { 0, 0, 0, 0 },
            borderWidth = 0,
            boxShadow = false,
        })
        topStatusRow:SetStyle({
            width = "100%",
            height = topHudHeight,
            alignItems = "flex-start",
            gap = 0,
        })
        currencyStatusPanel:SetStyle({
            position = "absolute",
            top = primaryHudHeight * 0.12,
            left = currencyLeft,
            width = currencyWidth,
            minWidth = currencyWidth,
            maxWidth = currencyWidth,
            height = primaryHudHeight * 0.72,
            padding = 0,
            gap = 0,
            backgroundColor = { 0, 0, 0, 0 },
            borderWidth = 0,
            boxShadow = false,
        })
        local currencyIconSize = Clamp(primaryHudHeight * 0.56, 32, 44)
        currencyStatusPanel.children[1]:SetVisible(true)
        currencyStatusPanel.children[1]:SetStyle({
            position = "absolute",
            top = (primaryHudHeight * 0.72 - currencyIconSize) * 0.5,
            left = 0,
            width = currencyIconSize,
            height = currencyIconSize,
        })
        currencyStatusPanel.children[2]:SetStyle({
            position = "absolute",
            top = 0,
            left = currencyIconSize + 6,
            right = 0,
            bottom = 0,
            padding = 0,
            gap = 0,
        })
        coinLabel:SetStyle({
            position = "absolute",
            top = primaryHudHeight * 0.18,
            left = 0,
            right = 0,
            height = primaryHudHeight * 0.4,
            fontSize = Clamp(primaryHudHeight * 0.22, 13, 17),
            fontWeight = "bold",
            textStroke = { width = 1, color = { 43, 29, 8, 255 } },
        })

        productionStatusPanel:SetStyle({
            position = "absolute",
            top = primaryHudHeight * 0.12,
            right = screenWidth - productionRight,
            width = productionWidth,
            minWidth = productionWidth,
            maxWidth = productionWidth,
            height = primaryHudHeight * 0.72,
            padding = 0,
            gap = 0,
            backgroundColor = { 0, 0, 0, 0 },
            borderWidth = 0,
            borderRadius = 0,
            boxShadow = false,
        })
        local productionIconSize = Clamp(primaryHudHeight * 0.5, 30, 40)
        productionStatusPanel.children[1]:SetVisible(true)
        productionStatusPanel.children[1]:SetStyle({
            position = "absolute",
            top = (primaryHudHeight * 0.72 - productionIconSize) * 0.5,
            left = 0,
            width = productionIconSize,
            height = productionIconSize,
        })
        productionStatusPanel.children[2]:SetStyle({
            position = "absolute",
            top = 0,
            left = productionIconSize + 5,
            right = 0,
            bottom = 0,
            padding = 0,
            gap = 0,
            alignItems = "flex-end",
        })
        revenueLabel:SetStyle({
            position = "absolute",
            top = primaryHudHeight * 0.2,
            left = 0,
            right = 0,
            height = primaryHudHeight * 0.34,
            fontSize = Clamp(primaryHudHeight * 0.145, 9, 11),
            fontWeight = "bold",
            textAlign = "right",
        })

        idleEarningsButton:SetVisible(true)
        idleEarningsButton:SetStyle({
            position = "absolute",
            top = (primaryHudHeight - topButtonHeight) * 0.5,
            right = screenWidth - idleLeft - idleWidth,
            width = idleWidth,
            minWidth = idleWidth,
            height = topButtonHeight,
            fontSize = 10,
        })
        layoutToggleButton:SetStyle({
            position = "absolute",
            top = (primaryHudHeight - topButtonHeight) * 0.5,
            right = screenWidth - layoutLeft - layoutWidth,
            width = layoutWidth,
            minWidth = layoutWidth,
            height = topButtonHeight,
        })
        landscapeAscensionButton:SetVisible(true)
        landscapeAscensionButton:SetStyle({
            position = "absolute",
            top = (primaryHudHeight - topButtonHeight) * 0.5,
            right = screenWidth - ascensionLeft - ascensionWidth,
            width = ascensionWidth,
            minWidth = ascensionWidth,
            maxWidth = ascensionWidth,
            height = topButtonHeight,
            minHeight = topButtonHeight,
            paddingLeft = 35,
            paddingRight = 3,
            textAlign = "left",
        })

        local gaugeIconSize = Clamp(primaryHudHeight * 0.58, 36, 44)
        local gaugeGap = Clamp(primaryHudHeight * 0.08, 5, 7)
        local gaugeHeight = Clamp(primaryHudHeight * 0.53, 32, 40)
        local gaugeTextHeight = Clamp(primaryHudHeight * 0.22, 14, 17)
        local loadRowHeight = gaugeHeight + gaugeTextHeight
        local loadTop = useSecondLoadRow
                and primaryHudHeight
                    + math.max(0, (secondLoadRowHeight - loadRowHeight) * 0.5)
            or primaryHudHeight * 0.13
        local gaugeIconInset = Clamp(screenWidth * 0.006, 7, 12)
        local gaugeBarInset = Clamp(screenWidth * 0.008, 9, 15)
        local gaugeContentLeft = gaugeIconInset
            + gaugeIconSize
            + gaugeGap
            + gaugeBarInset
        local gaugeContentWidth = loadWidth - gaugeContentLeft
        loadStatusRow:SetStyle({
            position = "absolute",
            top = loadTop,
            left = loadLeft,
            width = loadWidth,
            height = loadRowHeight,
            minHeight = loadRowHeight,
            padding = 0,
            gap = 0,
            justifyContent = "flex-start",
            backgroundColor = { 0, 0, 0, 0 },
            borderWidth = 0,
            boxShadow = false,
        })
        homeReturnButton:SetVisible(true)
        homeReturnButton:SetStyle({
            position = "absolute",
            top = (loadRowHeight - gaugeIconSize) * 0.5,
            left = gaugeIconInset,
            width = gaugeIconSize,
            minWidth = gaugeIconSize,
            maxWidth = gaugeIconSize,
            height = gaugeIconSize,
            minHeight = gaugeIconSize,
            padding = 0,
        })
        homeReturnButton.children[1]:SetStyle({
            position = "absolute",
            left = 3,
            top = 3,
            width = gaugeIconSize - 8,
            height = gaugeIconSize - 8,
        })
        loadStatusRow.children[2]:SetVisible(true)
        loadStatusRow.children[2]:SetStyle({
            position = "absolute",
            top = 0,
            left = gaugeContentLeft,
            width = gaugeContentWidth,
            height = gaugeHeight,
            minWidth = 0,
            padding = 0,
            pointerEvents = "none",
        })
        loadProgressBar:SetStyle({
            position = "absolute",
            top = 0,
            left = 0,
            width = gaugeContentWidth,
            height = gaugeHeight,
            trackColor = { 16, 65, 82, 220 },
        })
        loadGaugeLabel:SetStyle({
            position = "absolute",
            top = gaugeHeight,
            left = gaugeContentLeft,
            width = gaugeContentWidth,
            height = gaugeTextHeight,
            fontSize = Clamp(primaryHudHeight * 0.14, 9, 11),
            fontWeight = "bold",
            textAlign = "center",
            flexShrink = 0,
            whiteSpace = "nowrap",
            textStroke = { width = 1, color = { 4, 10, 14, 255 } },
        })

        ApplyLeftRailState(false)
        ApplyRightRailState(false)
        SetShopTab(activeShopTab == "upgrade" and "basic" or activeShopTab)
        if not gearWarehouseUnlocked_ then
            shopDrawer:SetVisible(false)
            leftRailExpandButton:SetVisible(false)
            leftRailCollapseHandle:SetVisible(false)
        end
        if not upgradeRailUnlocked_ then
            upgradeRegion:SetVisible(false)
            leftRailExpandButton:SetVisible(false)
            rightRailExpandButton:SetVisible(false)
            leftRailCollapseHandle:SetVisible(false)
            rightRailCollapseHandle:SetVisible(false)
        end
    end

    local function ApplyResponsiveLayout(options)
        if isLandscapeLayout then
            local uiScale = math.max(options.uiScale or 1, 0.01)
            local physicalLayoutHeight = options.height * uiScale
            local compactScale = math.max(
                0.68,
                math.min(1, physicalLayoutHeight / 400)
            )
            local isVeryCompactLandscape = physicalLayoutHeight < 320
            local targetGlobalActionPixels = isVeryCompactLandscape
                    and 46
                or 52
            local globalActionHeight = math.floor(
                targetGlobalActionPixels / uiScale + 0.5
            )
            local globalActionFont = math.max(
                compactScale < 0.8 and 9 or 10,
                math.floor(10 / uiScale + 0.5)
            )
            local cardHeight = isVeryCompactLandscape
                    and 56
                or math.min(
                    120,
                    math.max(66, math.floor(options.height * 0.23))
                )
            local iconSize = isVeryCompactLandscape
                    and 24
                or math.min(
                    50,
                    math.max(30, math.floor(cardHeight * 0.4))
                )
            local upgradeHeight = isVeryCompactLandscape
                    and 58
                or math.min(
                    128,
                    math.max(
                        76,
                        math.floor(
                            (
                                options.height
                                - globalActionHeight
                                - 82
                            ) / 3
                        )
                    )
                )
            local upgradeIconSize = isVeryCompactLandscape
                    and 24
                or math.min(
                    50,
                    math.max(30, math.floor(upgradeHeight * 0.36))
                )
            local upgradeActionHeight = math.max(
                20,
                math.floor(24 * compactScale)
            )
            local actionHeight = isVeryCompactLandscape
                    and 28
                or math.max(30, math.floor(38 * compactScale))
            local compactFont = math.max(7, math.floor(10 * compactScale))
            local railPadding = isVeryCompactLandscape
                    and 3
                or math.max(4, math.floor(8 * compactScale))

            layoutToggleButton:SetText("竖版")
            topHudFrame:SetVisible(true)
            titleLabel:SetVisible(false)
            clickValueLabel:SetVisible(false)
            essenceLabel:SetVisible(false)
            essenceOpenButton:SetVisible(false)
            powerStatusLabel:SetVisible(false)
            loadGaugeLabel:SetVisible(true)
            currencyStatusPanel.children[1]:SetVisible(true)
            currencyStatusPanel.children[1]:SetStyle({
                position = "absolute",
                top = 4,
                left = 0,
                width = 42,
                height = 42,
            })
            productionStatusPanel.children[1]:SetVisible(true)
            productionStatusPanel.children[1]:SetStyle({
                position = "absolute",
                top = 6,
                left = 0,
                width = 36,
                height = 36,
            })
            homeReturnButton:SetVisible(true)
            loadStatusRow.children[2]:SetVisible(true)
            coinLabel:SetStyle({
                position = "absolute",
                top = 4,
                left = 46,
                width = 92,
                height = 26,
                fontSize = 15,
                fontWeight = "bold",
                textStroke = { width = 1, color = { 43, 29, 8, 255 } },
            })
            revenueLabel:SetStyle({
                position = "absolute",
                top = 4,
                left = 38,
                width = 142,
                height = 24,
                fontSize = 10,
                fontWeight = "bold",
            })
            loadGaugeLabel:SetStyle({
                position = "absolute",
                top = 8,
                left = 0,
                width = 320,
                height = 22,
                fontSize = 10,
                fontWeight = "bold",
                flexShrink = 0,
                whiteSpace = "nowrap",
                textStroke = { width = 1, color = { 4, 10, 14, 255 } },
            })
            currencyStatusPanel:SetStyle({
                position = "absolute",
                top = 6,
                left = 22,
                width = 150,
                minWidth = 150,
                maxWidth = 150,
                height = 52,
                flexGrow = 0,
                paddingLeft = 0,
                paddingRight = 4,
                paddingTop = 2,
                paddingBottom = 2,
                gap = 4,
                backgroundColor = { 0, 0, 0, 0 },
                borderWidth = 0,
                boxShadow = false,
            })
            productionStatusPanel:SetStyle({
                position = "absolute",
                top = 8,
                right = 172,
                width = 190,
                minWidth = 190,
                maxWidth = 190,
                height = 48,
                flexGrow = 0,
                paddingHorizontal = 4,
                paddingVertical = 2,
                gap = 4,
                backgroundColor = { 0, 0, 0, 0 },
                borderWidth = 0,
                borderRadius = 0,
                boxShadow = false,
            })
            layoutToggleButton:SetStyle({
                position = "absolute",
                top = 12,
                right = 110,
                width = 70,
                minWidth = 70,
                height = 32,
                alignSelf = "stretch",
                fontSize = 9,
                fontWeight = "bold",
                paddingLeft = 6,
                paddingRight = 6,
                backgroundColor = { 76, 48, 16, 255 },
                hoverBackgroundColor = { 112, 70, 20, 255 },
                pressedBackgroundColor = { 48, 30, 10, 255 },
                borderWidth = { 1, 3, 4, 1 },
                borderColor = { 247, 180, 62, 245 },
                borderRadius = 0,
                boxShadow = {
                    { x = 3, y = 3, blur = 0, color = { 0, 0, 0, 80 } },
                },
            })
            loadProgressBar:SetStyle({
                height = 10,
                trackColor = { 4, 10, 14, 255 },
                trackBorderWidth = 2,
                trackBorderColor = { 91, 125, 137, 230 },
                borderRadius = 0,
            })
            loadStatusRow:SetStyle({
                position = "absolute",
                top = 29,
                left = 452,
                width = 320,
                height = 38,
                minHeight = 38,
                paddingHorizontal = 0,
                paddingVertical = 3,
                gap = 0,
                justifyContent = "center",
                backgroundColor = { 2, 22, 34, 95 },
                borderWidth = { 0, 0, 1, 0 },
                borderColor = { 47, 194, 219, 115 },
                boxShadow = false,
            })
            topStatusBar:SetStyle({
                left = 10,
                right = 10,
                top = 8,
                height = 58,
                padding = 0,
                gap = 0,
                borderWidth = 0,
                backgroundColor = { 0, 0, 0, 0 },
                boxShadow = false,
            })
            topStatusRow:SetStyle({
                width = "100%",
                height = 42,
                justifyContent = "space-between",
                alignItems = "flex-start",
                gap = 6,
            })
            shopGearDetailsPanel:SetStyle({
                padding = 16,
                gap = 10,
                borderRadius = 0,
            })
            shopGearDetailsTitleLabel:SetStyle({ fontSize = 15 })
            shopGearDetailsPriceLabel:SetStyle({ fontSize = 11 })
            shopGearDetailsDescriptionLabel:SetStyle({
                fontSize = 11,
                lineHeight = 1.35,
            })
            shopGearDetailsCloseButton:SetStyle({
                height = 38,
                fontSize = 11,
            })
            globalUpgradePanel:SetStyle({
                padding = 9,
                gap = 4,
                borderRadius = 0,
            })
            globalUpgradeTitleLabel:SetStyle({
                fontSize = 15,
                textAlign = "center",
            })
            globalUpgradeDescriptionLabel:SetStyle({
                fontSize = 9,
                textAlign = "center",
            })
            globalUpgradeSummaryLabel:SetStyle({
                fontSize = 9,
                lineHeight = 1.15,
                textAlign = "center",
            })
            for _, button in ipairs({
                globalIncomeUpgradeButton,
                decayUpgradeButton,
                offlineUpgradeButton,
                unlockBuildingButton,
            }) do
                button:SetStyle({
                    height = 32,
                    flexGrow = 1,
                    flexBasis = 0,
                    fontSize = 9,
                    paddingLeft = 4,
                    paddingRight = 4,
                })
            end
            globalUpgradeCloseButton:SetStyle({
                width = 88,
                height = 30,
                flexGrow = 0,
                alignSelf = "center",
                fontSize = 9,
            })
            ascensionPanel:SetStyle({
                padding = 12,
                gap = 7,
                borderRadius = 0,
            })
            ascensionTitleLabel:SetStyle({ fontSize = 17 })
            ascensionRewardLabel:SetStyle({ fontSize = 14 })
            ascensionProgressLabel:SetStyle({
                fontSize = 10,
                lineHeight = 1.2,
            })
            ascensionDescriptionLabel:SetStyle({
                fontSize = 10,
                lineHeight = 1.25,
                textAlign = "left",
            })
            ascensionActionRow:SetStyle({ gap = 5 })
            ascensionCloseButton:SetStyle({
                height = 36,
                fontSize = 10,
            })
            ascensionConfirmButton:SetStyle({
                height = 36,
                fontSize = 10,
            })
            upgradeTabButton:SetVisible(false)
            mainGearTabButton:SetVisible(false)
            shopTabRow:SetVisible(false)
            landscapeCategoryButton:SetVisible(true)
            shopTitleLabel:SetVisible(false)
            upgradeTitleLabel:SetVisible(false)
            levelLabel:SetVisible(false)
            shopInfoLabel:SetVisible(false)
            leftRailCollapseButton:SetVisible(false)
            rightRailCollapseButton:SetVisible(false)
            landscapeAscensionButton:SetVisible(true)
            landscapeAscensionButton:SetStyle({
                position = "absolute",
                top = 8,
                right = 0,
                width = 84,
                minWidth = 84,
                maxWidth = 84,
                height = 34,
                minHeight = 34,
                flexGrow = 0,
                flexShrink = 0,
                flexBasis = 84,
                alignSelf = "auto",
                fontSize = 10,
                fontWeight = "bold",
                textColor = { 196, 243, 255, 255 },
                backgroundColor = { 4, 32, 48, 190 },
                hoverBackgroundColor = { 11, 63, 82, 225 },
                pressedBackgroundColor = { 2, 22, 34, 235 },
                borderWidth = 1,
                borderColor = { 67, 220, 243, 210 },
                borderRadius = 17,
                boxShadow = {
                    { x = 0, y = 0, blur = 8, color = { 55, 218, 242, 42 } },
                },
                paddingLeft = 35,
                paddingRight = 3,
                textAlign = "left",
            })
            autoDriveButton:SetVisible(false)
            shopToggleDock:SetVisible(false)
            shopDrawer:SetVisible(true)
            shopBody:SetVisible(true)
            local safeMargin = 12
            local sectionGap = 16
            local shopTrayLeft = math.max(10, options.width * 0.065)
            local minimumShopWidth = math.min(360, options.width * 0.52)
            local maxDialSize = math.max(
                140,
                options.width
                    - shopTrayLeft
                    - minimumShopWidth
                    - sectionGap
                    - safeMargin
            )
            local desiredDialSize = math.min(
                360,
                options.width * 0.29,
                options.height - 128
            )
            currentRightRailWidth = math.max(
                140,
                math.min(desiredDialSize, maxDialSize)
            )
            currentLeftRailWidth = math.min(
                810,
                options.width
                    - shopTrayLeft
                    - currentRightRailWidth
                    - sectionGap
                    - safeMargin
            )
            local shopTrayWidth = math.max(1, currentLeftRailWidth)
            currentLeftRailWidth = shopTrayWidth
            local dialSize = currentRightRailWidth
            local dialTop = options.height - dialSize - safeMargin
            local shopContentWidth = math.max(1, shopTrayWidth - 24)
            shopBody:SetStyle({
                width = shopContentWidth,
                height = 114,
                maxHeight = 114,
                gap = 4,
            })
            shopDrawer:SetStyle({
                top = options.height - 146,
                left = shopTrayLeft,
                width = shopTrayWidth,
                height = 134,
                maxHeight = 134,
                overflow = "hidden",
                padding = 8,
                gap = 3,
                borderRadius = 0,
                backgroundColor = { 0, 0, 0, 0 },
                borderWidth = 0,
                boxShadow = false,
            })
            upgradeRegion:SetStyle({
                top = dialTop,
                right = safeMargin,
                width = dialSize,
                height = dialSize,
                maxHeight = dialSize,
                overflow = "hidden",
                padding = 0,
                gap = 0,
                borderWidth = 0,
                borderRadius = 0,
                backgroundColor = { 0, 0, 0, 0 },
            })
            upgradeRegion:SetVisible(true)
            leftRailExpandButton:SetStyle({
                top = math.max(52, math.floor(options.height * 0.16)),
            })
            rightRailExpandButton:SetStyle({
                top = math.max(52, math.floor(options.height * 0.16)),
            })
            ApplyLeftRailState(false)
            ApplyRightRailState(false)
            if not gearWarehouseUnlocked_ then
                shopDrawer:SetVisible(false)
                leftRailExpandButton:SetVisible(false)
                leftRailCollapseHandle:SetVisible(false)
            end
            if not upgradeRailUnlocked_ then
                upgradeRegion:SetVisible(false)
                rightRailExpandButton:SetVisible(false)
                rightRailCollapseHandle:SetVisible(false)
            end
            local upgradeRegionContent = upgradeRegion.children[2]
            if upgradeRegionContent then
                upgradeRegionContent:SetStyle({ gap = 3 })
            end
            mainGearShopPanel:SetVisible(true)
            upgradeShopPanel:SetVisible(false)
            local leftContentWidth = shopContentWidth
            basicShopPanel:SetStyle({
                position = "absolute",
                top = 24,
                left = 0,
                width = leftContentWidth,
                height = 88,
                flexDirection = "row",
                gap = 5,
            })
            transmissionShopPanel:SetStyle({
                position = "absolute",
                top = 24,
                left = 0,
                width = leftContentWidth,
                height = 88,
                flexDirection = "row",
                gap = 5,
            })
            factoryShopPanel:SetStyle({
                position = "absolute",
                top = 24,
                left = 0,
                width = leftContentWidth,
                height = 88,
            })
            local dialNodeWidth = math.min(88, math.max(58, math.floor(dialSize * 0.26)))
            local dialNodeHeight = math.min(80, math.max(68, math.floor(dialSize * 0.23)))
            local dialIconSize = math.min(34, math.max(24, math.floor(dialNodeHeight * 0.42)))
            local dialTitleTop = dialIconSize + 5
            local dialEffectTop = dialTitleTop + 14
            local torqueLeft, torqueTop = GetDialSectorNodePosition(
                dialSize,
                dialSize,
                1,
                dialNodeWidth,
                dialNodeHeight
            )
            local incomeLeft, incomeTop = GetDialSectorNodePosition(
                dialSize,
                dialSize,
                2,
                dialNodeWidth,
                dialNodeHeight
            )
            local clickLeft, clickTop = GetDialSectorNodePosition(
                dialSize,
                dialSize,
                3,
                dialNodeWidth,
                dialNodeHeight
            )
            local permanentLeft, permanentTop = GetDialSectorNodePosition(
                dialSize,
                dialSize,
                4,
                dialNodeWidth,
                dialNodeHeight
            )
            local dialCenterX, dialCenterY = GetDialGeometry(
                dialSize,
                dialSize
            )
            mainUpgradeRow:SetStyle({
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                height = dialSize,
                flexDirection = "column",
                flexWrap = "nowrap",
                alignItems = "stretch",
                justifyContent = "flex-start",
                gap = 0,
                overflow = "hidden",
            })
            mainTorqueUpgradeButton:SetStyle({
                position = "absolute",
                top = torqueTop,
                left = torqueLeft,
            })
            mainCircleIncomeUpgradeButton:SetStyle({
                position = "absolute",
                top = incomeTop,
                left = incomeLeft,
            })
            clickUpgradeWrapper:SetStyle({
                position = "absolute",
                left = clickLeft,
                top = clickTop,
                width = dialNodeWidth,
                minWidth = dialNodeWidth,
                height = dialNodeHeight,
                flexGrow = 0,
                flexShrink = 0,
                flexBasis = dialNodeWidth,
                overflow = "visible",
            })
            upgradeButton:SetStyle({
                position = "absolute",
                top = 0,
                left = 0,
            })
            globalUpgradeOpenButton:SetStyle({
                position = "absolute",
                top = permanentTop,
                left = permanentLeft,
            })
            permanentUpgradeIcon:SetStyle({
                position = "absolute",
                left = permanentLeft + (dialNodeWidth - dialIconSize) * 0.5,
                top = permanentTop + 2,
                width = dialIconSize,
                height = dialIconSize,
            })
            permanentUpgradeTitleLabel:SetStyle({
                position = "absolute",
                left = permanentLeft + 2,
                top = permanentTop + dialTitleTop,
                width = dialNodeWidth - 4,
                height = 13,
                minHeight = 13,
            })
            permanentUpgradeLevelLabel:SetStyle({
                position = "absolute",
                left = permanentLeft + 2,
                top = permanentTop + dialEffectTop,
                width = dialNodeWidth - 4,
                height = 13,
                minHeight = 13,
            })
            modifyCoreButton:SetStyle({
                position = "absolute",
                left = dialCenterX - 66,
                top = dialCenterY - 66,
                width = 132,
                height = 132,
                borderRadius = 66,
            })
            modifyCoreIcon:SetStyle({
                position = "absolute",
                left = dialCenterX - 22,
                top = dialCenterY - 48,
                width = 44,
                height = 44,
                zIndex = 13,
            })
            modifyCoreLabel:SetStyle({
                position = "absolute",
                left = dialCenterX - 38,
                top = dialCenterY + 2,
                width = 76,
                height = 40,
                minHeight = 40,
                fontSize = 13,
                lineHeight = 1,
                zIndex = 13,
            })
            mainGearShopPanel:SetStyle({
                position = "absolute",
                top = 0,
                left = 0,
                right = 0,
                height = dialSize,
                overflow = "hidden",
                gap = 0,
            })
            upgradeShopPanel:SetStyle({
                position = "absolute",
                left = 0,
                right = 0,
                top = 0,
                height = 1,
                flexGrow = 0,
                flexShrink = 0,
                flexBasis = 1,
                overflow = "hidden",
                gap = 0,
            })
            globalActionRow:SetStyle({
                width = "100%",
                height = 44,
                flexGrow = 0,
                flexShrink = 0,
                flexBasis = 44,
                flexDirection = "row",
                alignItems = "center",
                justifyContent = "center",
                gap = 5,
            })
            for _, card in ipairs({
                buySmallGearButton,
                buyMediumGearButton,
                buyLargeGearButton,
                buyCompoundGearButton,
                buyMommaGearButton,
                buyLubricantGearButton,
                buyCoinGearButton,
            }) do
                card:SetStyle({
                    width = 0,
                    minWidth = 0,
                    height = 88,
                    flexGrow = 1,
                    flexShrink = 1,
                    flexBasis = 0,
                    padding = 3,
                    gap = 1,
                    backgroundColor = { 5, 30, 45, 190 },
                    borderWidth = 1,
                    borderColor = { 55, 205, 231, 180 },
                    boxShadow = false,
                })
                card.props.gearIconSlot:SetStyle({
                    position = "relative",
                    left = 0,
                    top = 0,
                    width = 52,
                    minWidth = 52,
                    height = 52,
                    minHeight = 52,
                    marginLeft = 10,
                    marginRight = 0,
                })
                card.props.gearImage:SetStyle({
                    width = 44,
                    height = 44,
                    marginLeft = 0,
                })
                card.props.modelLabel:SetStyle({
                    fontSize = 9,
                    textAlign = "left",
                })
                card.props.priceLabel:SetStyle({
                    fontSize = 11,
                    textAlign = "left",
                })
            end
            landscapeCategoryButton:SetStyle({
                position = "absolute",
                top = 0,
                left = 0,
                width = 90,
                minWidth = 90,
                height = 26,
                alignSelf = "center",
                fontSize = 8,
                fontWeight = "bold",
                textColor = { 172, 235, 246, 255 },
                backgroundColor = { 4, 28, 43, 205 },
                hoverBackgroundColor = { 10, 56, 73, 230 },
                pressedBackgroundColor = { 2, 18, 29, 235 },
                borderWidth = 1,
                borderColor = { 56, 211, 236, 190 },
                borderRadius = 5,
                boxShadow = false,
                paddingLeft = 4,
                paddingRight = 4,
            })
            autoDriveButton:SetVisible(false)
            factoryStatusLabel:SetStyle({ fontSize = compactFont })
            factoryClaimButton:SetStyle({
                width = leftContentWidth,
                minWidth = 0,
                height = actionHeight,
                fontSize = compactFont,
                paddingLeft = 2,
                paddingRight = 2,
            })
            for _, button in ipairs({
                mainTorqueUpgradeButton,
                mainCircleIncomeUpgradeButton,
                upgradeButton,
            }) do
                button:SetStyle({
                    width = dialNodeWidth,
                    minWidth = dialNodeWidth,
                    height = dialNodeHeight,
                    minHeight = dialNodeHeight,
                    flexGrow = 0,
                    flexShrink = 0,
                    flexBasis = dialNodeWidth,
                    paddingTop = 1,
                    paddingRight = 1,
                    paddingBottom = 1,
                    paddingLeft = 1,
                    gap = 0,
                    backgroundColor = { 0, 0, 0, 0 },
                    borderWidth = 0,
                    borderColor = { 0, 0, 0, 0 },
                    borderRadius = 0,
                    boxShadow = false,
                })
                button.props.gearImage:SetStyle({
                    position = "absolute",
                    top = 2,
                    left = (dialNodeWidth - dialIconSize) * 0.5,
                    width = dialIconSize,
                    height = dialIconSize,
                    flexShrink = 0,
                    marginBottom = 0,
                })
                button.props.modelLabel:SetStyle({
                    position = "absolute",
                    top = dialTitleTop,
                    left = 2,
                    width = dialNodeWidth - 4,
                    height = 13,
                    minHeight = 13,
                    fontSize = 8,
                    marginTop = 0,
                    lineHeight = 1,
                    flexShrink = 0,
                    whiteSpace = "nowrap",
                    textAlign = "center",
                })
                button.props.effectLabel:SetVisible(true)
                button.props.effectLabel:SetStyle({
                    position = "absolute",
                    top = dialEffectTop,
                    left = 2,
                    width = dialNodeWidth - 4,
                    height = 13,
                    minHeight = 13,
                    fontSize = 8,
                    fontWeight = "bold",
                    lineHeight = 1,
                    flexShrink = 0,
                    whiteSpace = "nowrap",
                    textAlign = "center",
                    fontColor = { 216, 239, 245, 255 },
                })
                button.props.priceLabel:SetVisible(false)
            end
            globalUpgradeOpenButton:SetStyle({
                width = dialNodeWidth,
                minWidth = dialNodeWidth,
                maxWidth = dialNodeWidth,
                height = dialNodeHeight,
                minHeight = dialNodeHeight,
                flexGrow = 0,
                flexShrink = 0,
                flexBasis = dialNodeWidth,
                alignSelf = "center",
                fontSize = 9,
                fontWeight = "bold",
                textColor = { 220, 248, 255, 255 },
                backgroundColor = { 0, 0, 0, 0 },
                hoverBackgroundColor = { 40, 207, 234, 30 },
                pressedBackgroundColor = { 40, 207, 234, 55 },
                borderWidth = 0,
                borderColor = { 0, 0, 0, 0 },
                borderRadius = 0,
                boxShadow = false,
                paddingTop = 34,
                paddingRight = 2,
                paddingBottom = 2,
                paddingLeft = 2,
                lineHeight = 1,
            })
            for _, button in pairs(shopTabButtons) do
                button:SetStyle({
                    fontSize = 9,
                    paddingLeft = 2,
                    paddingRight = 2,
                })
            end
            SetShopTab(activeShopTab == "upgrade" and "basic" or activeShopTab)
            ApplyLandscapeSideRailLayout(options)
        else
            layoutToggleButton:SetText("横版")
            titleLabel:SetVisible(false)
            clickValueLabel:SetVisible(false)
            essenceOpenButton:SetVisible(false)
            powerStatusLabel:SetVisible(false)
            loadGaugeLabel:SetVisible(false)
            coinLabel:SetStyle({
                fontSize = 16,
                fontWeight = "bold",
            })
            revenueLabel:SetStyle({
                fontSize = 9,
                textAlign = "right",
            })
            essenceLabel:SetStyle({
                fontSize = 9,
                textAlign = "right",
            })
            layoutToggleButton:SetStyle({
                height = 28,
                minWidth = 48,
                fontSize = 9,
                paddingLeft = 7,
                paddingRight = 7,
                borderRadius = 0,
            })
            loadProgressBar:SetStyle({ height = 6 })
            topStatusBar:SetStyle({
                top = 8,
                left = 10,
                right = 10,
                padding = 0,
                gap = 6,
                borderWidth = 0,
                backgroundColor = { 0, 0, 0, 0 },
                boxShadow = false,
            })
            local topStatusRow = topStatusBar.children[1]
            if topStatusRow then
                topStatusRow:SetStyle({ gap = 4 })
            end
            shopTabRow:SetVisible(true)
            mainGearTabButton:SetVisible(true)
            upgradeTabButton:SetVisible(true)
            shopBody:SetStyle({ height = 246, gap = 8 })
            mainGearShopPanel:SetStyle({ gap = 8 })
            autoDriveButton:SetStyle({
                height = 34,
                fontSize = 10,
                borderRadius = 0,
            })
            levelLabel:SetStyle({
                fontSize = 12,
                fontWeight = "bold",
                textAlign = "center",
            })
            mainUpgradeRow:SetStyle({
                flexDirection = "row",
                alignItems = "stretch",
                gap = 7,
            })
            clickUpgradeWrapper:SetStyle({
                height = 108,
                flexGrow = 1,
                flexShrink = 1,
                flexBasis = 0,
                minWidth = 0,
            })
            for _, card in ipairs({
                mainTorqueUpgradeButton,
                mainCircleIncomeUpgradeButton,
                upgradeButton,
            }) do
                card:SetStyle({
                    height = 108,
                    flexGrow = 1,
                    flexBasis = 0,
                    flexShrink = 1,
                    paddingTop = 8,
                    paddingRight = 7,
                    paddingBottom = 8,
                    paddingLeft = 7,
                    gap = 3,
                    flexDirection = "column",
                    alignItems = "center",
                    justifyContent = "center",
                    borderRadius = 0,
                    borderWidth = 1,
                    borderColor = { 111, 130, 145, 210 },
                    backgroundColor = { 23, 31, 38, 248 },
                })
                card.props.gearImage:SetStyle({
                    width = 36,
                    height = 36,
                    flexShrink = 0,
                    alignSelf = "center",
                })
                card.props.modelLabel:SetStyle({
                    width = "100%",
                    fontSize = 10,
                    textAlign = "center",
                    flexShrink = 0,
                    alignSelf = "center",
                })
                card.props.effectLabel:SetStyle({
                    width = "100%",
                    fontSize = 8,
                    textAlign = "center",
                    flexShrink = 0,
                    alignSelf = "center",
                })
                card.props.priceLabel:SetStyle({
                    width = "100%",
                    fontSize = 12,
                    fontWeight = "bold",
                    textAlign = "center",
                    flexShrink = 0,
                    alignSelf = "center",
                })
            end
            upgradeShopPanel:SetStyle({ gap = 10 })
            globalActionRow:SetStyle({
                flexDirection = "row",
                alignItems = "stretch",
                gap = 10,
            })
            globalUpgradeOpenButton:SetStyle({
                height = 46,
                flexGrow = 1,
                flexBasis = 0,
                alignSelf = "stretch",
                fontSize = 11,
                fontWeight = "bold",
                textColor = { 204, 255, 232, 255 },
                backgroundColor = { 20, 76, 63, 255 },
                hoverBackgroundColor = { 29, 116, 91, 255 },
                pressedBackgroundColor = { 12, 48, 40, 255 },
                borderWidth = 2,
                borderColor = { 71, 226, 171, 255 },
                borderRadius = 0,
            })
            ascensionOpenButton:SetStyle({
                height = 46,
                flexGrow = 1,
                flexBasis = 0,
                alignSelf = "stretch",
                fontSize = 11,
                fontWeight = "bold",
                textColor = { 246, 214, 255, 255 },
                backgroundColor = { 66, 32, 91, 255 },
                hoverBackgroundColor = { 101, 46, 137, 255 },
                pressedBackgroundColor = { 42, 19, 59, 255 },
                borderWidth = 2,
                borderColor = { 213, 100, 255, 255 },
                borderRadius = 0,
            })
            SetShopExpanded(false)
            SetShopTab("basic")
        end
    end

    UI.SetRoot(root)

    return {
        root = root,
        applyResponsiveLayout = ApplyResponsiveLayout,
        layoutToggleButton = layoutToggleButton,
        topStatusBar = topStatusBar,
        upgradeRegion = upgradeRegion,
        leftRailExpandButton = leftRailExpandButton,
        rightRailExpandButton = rightRailExpandButton,
        leftRailCollapseHandle = leftRailCollapseHandle,
        rightRailCollapseHandle = rightRailCollapseHandle,
        setGearWarehouseUnlocked = function(unlocked)
            if not isLandscapeLayout then
                return
            end
            local wasUnlocked = gearWarehouseUnlocked_
            gearWarehouseUnlocked_ = unlocked == true
            if not gearWarehouseUnlocked_ then
                landscapeLeftRailCollapsed_ = true
            elseif not wasUnlocked then
                landscapeLeftRailCollapsed_ = true
            end
            shopDrawer:SetVisible(gearWarehouseUnlocked_)
            ApplyLeftRailState(false)
        end,
        setShopGearRevealed = function(card, revealed, unlockText)
            card.props.revealed = revealed == true
            card.props.gearIconSlot:SetVisible(true)
            card.props.gearImage:SetVisible(revealed)
            card.props.lockedQuestionIcon:SetVisible(not revealed)
            card.props.lockedStatusLabel:SetVisible(not revealed)
            card.props.lockedActionLabel:SetVisible(not revealed)
            card.props.slotLabel:SetVisible(
                revealed and card.props.hasSlotNumber
            )
            card.props.countLabel:SetVisible(
                revealed and card.props.hasSlotNumber
            )
            card.props.modelLabel:SetText(
                revealed and card.props.revealedModelText or "未解锁"
            )
            local cardHeight = card.props.layoutCardHeight
            if cardHeight then
                card.props.modelLabel:SetStyle({
                    top = cardHeight * (revealed and 0.27 or 0.15),
                })
                card.props.priceLabel:SetStyle({
                    top = cardHeight * (revealed and 0.57 or 0.68),
                    height = cardHeight * (revealed and 0.22 or 0.2),
                })
            end
            if not revealed then
                card.props.priceLabel:SetText(unlockText)
            end
            card:SetClickable(revealed)
            if not revealed then
                card:SetOpacity(0.72)
            end
        end,
        setUpgradeRailUnlocked = function(unlocked)
            if not isLandscapeLayout then
                return
            end
            local wasUnlocked = upgradeRailUnlocked_
            upgradeRailUnlocked_ = unlocked == true
            if not upgradeRailUnlocked_ then
                landscapeLeftRailCollapsed_ = true
                landscapeRightRailCollapsed_ = true
                HideMainUpgradeDetails()
            elseif not wasUnlocked then
                landscapeRightRailCollapsed_ = true
            end
            shopDrawer:SetVisible(gearWarehouseUnlocked_)
            upgradeRegion:SetVisible(upgradeRailUnlocked_)
            ApplyLeftRailState(false)
            ApplyRightRailState(false)
        end,
        setPermanentUpgradeRevealed = function(revealed, unlockText)
            permanentUpgradeRevealed_ = revealed == true
            permanentUpgradeIcon:SetVisible(permanentUpgradeRevealed_)
            permanentLockedQuestionIcon:SetVisible(
                not permanentUpgradeRevealed_
            )
            permanentUpgradeTitleLabel:SetText(
                permanentUpgradeRevealed_ and "永久强化" or "未解锁"
            )
            permanentUpgradeLevelLabel:SetText(
                permanentUpgradeRevealed_ and "Lv.0" or "未解锁"
            )
            permanentUpgradePriceLabel:SetText(
                permanentUpgradeRevealed_ and "精华升级" or unlockText
            )
            permanentUpgradeActionLabel:SetText(
                permanentUpgradeRevealed_ and "升级" or "未解锁"
            )
            permanentUpgradeActionLabel:SetStyle({
                fontColor = permanentUpgradeRevealed_
                        and { 255, 225, 151, 255 }
                    or { 170, 185, 191, 255 },
                backgroundColor = permanentUpgradeRevealed_
                        and { 84, 56, 17, 250 }
                    or { 28, 38, 44, 245 },
                borderColor = permanentUpgradeRevealed_
                        and { 245, 187, 69, 245 }
                    or { 91, 112, 122, 210 },
            })
        end,
        coinLabel = coinLabel,
        essenceLabel = essenceLabel,
        clickValueLabel = clickValueLabel,
        revenueLabel = revenueLabel,
        idleEarningsButton = idleEarningsButton,
        powerStatusLabel = powerStatusLabel,
        loadGaugeLabel = loadGaugeLabel,
        loadProgressBar = loadProgressBar,
        levelLabel = levelLabel,
        shopInfoLabel = shopInfoLabel,
        clickUpgradeConfirmButton = clickUpgradeConfirmButton,
        clickUpgradeResultLabel = clickUpgradeResultLabel,
        refreshMainUpgradeDetails = RefreshMainUpgradeDetails,
        hideMainUpgradeDetails = HideMainUpgradeDetails,
        upgradeButton = upgradeButton,
        mainTorqueUpgradeButton = mainTorqueUpgradeButton,
        mainCircleIncomeUpgradeButton = mainCircleIncomeUpgradeButton,
        buySmallGearButton = buySmallGearButton,
        buySmallGearPriceLabel = buySmallGearPriceLabel,
        buyMediumGearButton = buyMediumGearButton,
        buyMediumGearPriceLabel = buyMediumGearPriceLabel,
        buyLargeGearButton = buyLargeGearButton,
        buyLargeGearPriceLabel = buyLargeGearPriceLabel,
        buyCompoundGearButton = buyCompoundGearButton,
        buyCompoundGearPriceLabel = buyCompoundGearPriceLabel,
        buyMommaGearButton = buyMommaGearButton,
        buyMommaGearPriceLabel = buyMommaGearPriceLabel,
        buyLubricantGearButton = buyLubricantGearButton,
        buyLubricantGearPriceLabel = buyLubricantGearPriceLabel,
        buyCoinGearButton = buyCoinGearButton,
        buyCoinGearPriceLabel = buyCoinGearPriceLabel,
        factoryStatusLabel = factoryStatusLabel,
        factoryClaimButton = factoryClaimButton,
        shopDrawer = shopDrawer,
        shopBody = shopBody,
        shopToggleButton = shopToggleButton,
        basicShopPanel = basicShopPanel,
        transmissionShopPanel = transmissionShopPanel,
        factoryShopPanel = factoryShopPanel,
        upgradeShopPanel = upgradeShopPanel,
        autoDriveButton = autoDriveButton,
        gearDetailsPanel = gearDetailsPanel,
        gearDetailsTitleLabel = gearDetailsTitleLabel,
        gearDetailsStatusLabel = gearDetailsStatusLabel,
        gearDetailsStatsLabel = gearDetailsStatsLabel,
        gearDetailsUpgradeLabel = gearDetailsUpgradeLabel,
        gearDetailsEssenceLabel = gearDetailsEssenceLabel,
        gearUpgradeButton = gearUpgradeButton,
        gearDeleteButton = gearDetailsCard:FindById("gearDeleteButton"),
        gearDetailsCloseButton = gearDetailsCloseButton,
        shopGearDetailsPanel = shopGearDetailsPanel,
        shopGearDetailsTitleLabel = shopGearDetailsTitleLabel,
        shopGearDetailsPriceLabel = shopGearDetailsPriceLabel,
        shopGearDetailsDescriptionLabel = shopGearDetailsDescriptionLabel,
        shopGearDetailsCloseButton = shopGearDetailsCloseButton,
        currencyGeneratorDetailsPanel = currencyGeneratorDetails.panel,
        currencyGeneratorDetailsTitleLabel = currencyGeneratorDetails.titleLabel,
        currencyGeneratorDetailsStatusLabel = currencyGeneratorDetails.statusLabel,
        currencyGeneratorDetailsDescriptionLabel = currencyGeneratorDetails.descriptionLabel,
        currencyGeneratorDetailsPrimaryButton = currencyGeneratorDetails.primaryButton,
        currencyGeneratorDetailsSecondaryButton = currencyGeneratorDetails.secondaryButton,
        currencyGeneratorDetailsActionDock = currencyGeneratorDetails.actionDock,
        globalUpgradePanel = globalUpgradePanel,
        globalUpgradeSummaryLabel = globalUpgradeSummaryLabel,
        globalIncomeUpgradeButton = globalIncomeUpgradeButton,
        decayUpgradeButton = decayUpgradeButton,
        offlineUpgradeButton = offlineUpgradeButton,
        unlockBuildingButton = unlockBuildingButton,
        globalUpgradeOpenButton = globalUpgradeOpenButton,
        permanentUpgradeLevelLabel = permanentUpgradeLevelLabel,
        globalUpgradeCloseButton = globalUpgradeCloseButton,
        ascensionPanel = ascensionPanel,
        ascensionOpenButton = ascensionOpenButton,
        homeReturnButton = homeReturnButton,
        landscapeAscensionButton = landscapeAscensionButton,
        ascensionRewardLabel = ascensionRewardLabel,
        ascensionProgressLabel = ascensionProgressLabel,
        ascensionConfirmButton = ascensionConfirmButton,
        ascensionToastLabel = ascensionToastLabel,
        offlineRewardPanel = offlineRewardPanel,
        offlineRewardLabel = offlineRewardLabel,
        claimOfflineButton = claimOfflineButton,
        canvasInputArea = canvasInputArea,
        recycleDropZone = recycleDropZone,
        recycleRefundLabel = recycleDropZone:FindById("recycleRefundLabel"),
    }
end

return GameUI
