local UI = require("urhox-libs/UI")
local Widget = require("urhox-libs/UI/Core/Widget")

local TutorialUI = {}

TutorialUI.Version = 2
TutorialUI.FirstStep = "tap_main"
TutorialUI.LubricantFirstStep = "lubricant_earn"

local MASK_COLOR = { 2, 8, 15, 190 }
local GOLD = { 255, 205, 73, 255 }
local CYAN = { 70, 226, 255, 255 }
local WHITE = { 252, 249, 236, 255 }
local INK = { 7, 14, 20, 255 }

local STEP_CONTENT = {
    tap_main = {
        number = 1,
        title = "启动主齿轮",
        message = "点击中央主齿轮，赚取第一笔金币。",
        action = "点击齿轮",
    },
    earn_torque = {
        number = 2,
        title = "积攒改装资金",
        message = "继续点击主齿轮，攒到 ￥25，解锁动力改装。",
        action = "继续点击",
    },
    open_upgrade = {
        number = 3,
        title = "展开动力改装",
        message = "点击右侧的动力改装把手，打开升级面板。",
        action = "点击把手",
    },
    select_torque = {
        number = 3,
        title = "强化主轴扭矩",
        message = "选择“主轴扭矩”，为齿轮网络提供动力。",
        action = "选择升级",
    },
    confirm_torque = {
        number = 3,
        title = "确认扭矩升级",
        message = "花费 ￥25 完成升级，同时解锁自动运转。",
        action = "确认升级",
    },
    earn_gear = {
        number = 4,
        title = "准备第一颗齿轮",
        message = "继续点击并等待自动运转，累计赚到 ￥100。",
        action = "积攒 ￥100",
    },
    open_shop = {
        number = 5,
        title = "展开齿轮仓库",
        message = "点击左侧仓库把手，打开齿轮货架。",
        action = "点击把手",
    },
    drag_small = {
        number = 5,
        title = "拖出小型齿轮",
        message = "按住小型齿轮，把它拖到中央主齿轮旁边。",
        action = "按住并拖动",
    },
    place_small = {
        number = 6,
        title = "完成齿轮啮合",
        message = "拖到高亮区域，靠近主齿轮出现吸附后松手。",
        action = "拖动后松手",
    },
    lubricant_earn = {
        number = 1,
        total = 4,
        title = "齿轮卡住了",
        message = "润滑耗尽会让传动停机。继续赚钱，攒到 ￥750 解锁巡游润滑齿轮。",
        action = "继续赚钱",
    },
    lubricant_open_shop = {
        number = 2,
        total = 4,
        title = "打开齿轮仓库",
        message = "润滑齿轮已解锁，点击左侧仓库把手查看它。",
        action = "点击仓库把手",
    },
    lubricant_drag = {
        number = 3,
        total = 4,
        title = "拖出巡游润滑齿轮",
        message = "按住 OIL-08 巡游润滑齿轮，把它拖到工坊中央。",
        action = "按住并拖动",
    },
    lubricant_place = {
        number = 4,
        total = 4,
        title = "恢复传动",
        message = "把润滑齿轮放到高亮区域，等待它自动为普通齿轮补充润滑。",
        action = "拖动后松手",
    },
    generator_details = {
        number = 7,
        total = 7,
        title = "认识货币生成器",
        message = "点击货币生成器，查看它的产出、扭矩需求和当前运行状态。",
        action = "点击货币生成器",
    },
}

---@class GearWorkshopTutorialVisual : Widget
---@overload fun(props?: table): GearWorkshopTutorialVisual
local TutorialVisual = Widget:Extend("GearWorkshopTutorialVisual")

function TutorialVisual:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    props.position = "absolute"
    props.left = 0
    props.top = 0
    props.width = "100%"
    props.height = "100%"
    Widget.Init(self, props)
    self.phase_ = 0
    self.targetRect_ = nil
    self.content_ = STEP_CONTENT.tap_main
    self.screenWidth_ = 1
    self.screenHeight_ = 1
    self.progressText_ = ""
    self.progressTotal_ = 6
end

function TutorialVisual:Update(timeStep)
    self.phase_ = self.phase_ + math.max(0, timeStep)
end

function TutorialVisual:SetGuideData(rect, content, screenWidth, screenHeight, progressText)
    self.targetRect_ = rect
    self.content_ = content or STEP_CONTENT.tap_main
    self.screenWidth_ = math.max(1, screenWidth or 1)
    self.screenHeight_ = math.max(1, screenHeight or 1)
    self.progressText_ = progressText or ""
    self.progressTotal_ = self.content_.total or 6
end

local function DrawRoundedFillStroke(vg, x, y, width, height, radius, fill, stroke, strokeWidth)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, x, y, width, height, radius)
    nvgFillColor(vg, nvgRGBA(fill[1], fill[2], fill[3], fill[4]))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(stroke[1], stroke[2], stroke[3], stroke[4]))
    nvgStrokeWidth(vg, strokeWidth)
    nvgStroke(vg)
end

local function DrawTutorialHand(vg, x, y, phase)
    local bob = math.sin(phase * 5.2) * 6
    local press = (math.sin(phase * 5.2) + 1) * 0.5
    local scale = 0.78 + press * 0.05

    nvgSave(vg)
    nvgTranslate(vg, x, y + bob)
    nvgScale(vg, scale, scale)
    nvgRotate(vg, -0.28)

    DrawRoundedFillStroke(
        vg,
        10,
        26,
        58,
        52,
        18,
        WHITE,
        INK,
        5
    )
    DrawRoundedFillStroke(
        vg,
        36,
        -12,
        21,
        58,
        10,
        WHITE,
        INK,
        5
    )
    DrawRoundedFillStroke(
        vg,
        -3,
        38,
        36,
        20,
        10,
        WHITE,
        INK,
        5
    )
    DrawRoundedFillStroke(
        vg,
        18,
        67,
        44,
        22,
        3,
        GOLD,
        INK,
        5
    )

    nvgRestore(vg)
end

function TutorialVisual:Render(vg)
    local rect = self.targetRect_
    if not rect then
        return
    end

    local pulse = (math.sin(self.phase_ * 4.2) + 1) * 0.5
    local glowAlpha = math.floor(105 + pulse * 90)
    local expansion = 4 + pulse * 5
    local x = rect.x - expansion
    local y = rect.y - expansion
    local width = rect.w + expansion * 2
    local height = rect.h + expansion * 2

    nvgBeginPath(vg)
    nvgRoundedRect(vg, x, y, width, height, 8)
    nvgStrokeColor(vg, nvgRGBA(GOLD[1], GOLD[2], GOLD[3], glowAlpha))
    nvgStrokeWidth(vg, 7 + pulse * 3)
    nvgStroke(vg)

    nvgBeginPath(vg)
    nvgRoundedRect(vg, rect.x, rect.y, rect.w, rect.h, 6)
    nvgStrokeColor(vg, nvgRGBA(CYAN[1], CYAN[2], CYAN[3], 255))
    nvgStrokeWidth(vg, 3)
    nvgStroke(vg)

    local rippleRadius = math.min(rect.w, rect.h) * (0.20 + pulse * 0.18)
    nvgBeginPath(vg)
    nvgCircle(
        vg,
        rect.x + rect.w * 0.5,
        rect.y + rect.h * 0.5,
        rippleRadius
    )
    nvgStrokeColor(vg, nvgRGBA(255, 224, 116, math.floor(210 * (1 - pulse))))
    nvgStrokeWidth(vg, 3)
    nvgStroke(vg)

    local handX = math.min(
        self.screenWidth_ - 82,
        rect.x + rect.w * 0.62
    )
    local handY = rect.y + rect.h + 14
    if handY + 92 > self.screenHeight_ then
        handY = rect.y - 90
    end
    DrawTutorialHand(vg, handX, handY, self.phase_)

    local cardWidth = math.min(440, self.screenWidth_ - 32)
    local cardHeight = 150
    local cardX = math.max(
        16,
        math.min(
            self.screenWidth_ - cardWidth - 16,
            rect.x + rect.w * 0.5 - cardWidth * 0.5
        )
    )
    local cardY = rect.y - cardHeight - 28
    if cardY < 18 then
        cardY = rect.y + rect.h + 104
    end
    cardY = math.max(18, math.min(self.screenHeight_ - cardHeight - 18, cardY))

    nvgBeginPath(vg)
    nvgRect(vg, cardX + 8, cardY + 8, cardWidth, cardHeight)
    nvgFillColor(vg, nvgRGBA(0, 0, 0, 125))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgRect(vg, cardX, cardY, cardWidth, cardHeight)
    nvgFillColor(vg, nvgRGBA(12, 38, 54, 252))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(5, 12, 18, 255))
    nvgStrokeWidth(vg, 5)
    nvgStroke(vg)

    nvgBeginPath(vg)
    nvgRect(vg, cardX + 5, cardY + 5, 10, cardHeight - 10)
    nvgFillColor(vg, nvgRGBA(GOLD[1], GOLD[2], GOLD[3], 255))
    nvgFill(vg)

    nvgFontFace(vg, "sans-bold")
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgFontSize(vg, 14)
    nvgFillColor(vg, nvgRGBA(CYAN[1], CYAN[2], CYAN[3], 255))
    nvgText(
        vg,
        cardX + 30,
        cardY + 18,
        string.format(
            "新手教程  %d / %d",
            self.content_.number or 1,
            self.progressTotal_
        )
    )

    nvgFontSize(vg, 23)
    nvgFillColor(vg, nvgRGBA(255, 229, 139, 255))
    nvgText(vg, cardX + 30, cardY + 44, self.content_.title or "")

    nvgFontSize(vg, 15)
    nvgFillColor(vg, nvgRGBA(235, 244, 247, 255))
    nvgTextBox(
        vg,
        cardX + 30,
        cardY + 78,
        cardWidth - 60,
        self.content_.message or ""
    )

    local footer = self.content_.action or ""
    if self.progressText_ ~= "" then
        footer = footer .. "  ·  " .. self.progressText_
    end
    nvgFontSize(vg, 13)
    nvgFillColor(vg, nvgRGBA(174, 224, 232, 255))
    nvgText(vg, cardX + 30, cardY + 126, footer)
end

---@class GearWorkshopTutorialLayer : Widget
---@overload fun(props?: table): GearWorkshopTutorialLayer
local TutorialLayer = Widget:Extend("GearWorkshopTutorialLayer")

function TutorialLayer:Init(props)
    props = props or {}
    props.position = "absolute"
    props.left = 0
    props.top = 0
    props.width = "100%"
    props.height = "100%"
    props.pointerEvents = "box-none"
    props.zIndex = 20000
    Widget.Init(self, props)
    self.controller_ = nil
end

function TutorialLayer:Update(timeStep)
    if self.controller_ then
        self.controller_:Update(timeStep)
    end
end

local Controller = {}
Controller.__index = Controller

local function IsEffectivelyVisible(widget)
    local current = widget
    while current do
        if not current:IsVisible() then
            return false
        end
        current = current.parent
    end
    return widget ~= nil
end

local function WidgetRect(widget)
    if not widget or not IsEffectivelyVisible(widget) then
        return nil
    end
    local layout = widget:GetAbsoluteLayoutForHitTest()
    if not layout or layout.w <= 0 or layout.h <= 0 then
        return nil
    end
    return { x = layout.x, y = layout.y, w = layout.w, h = layout.h }
end

function Controller:SetStep(step)
    if self.step_ == step then
        return
    end
    if STEP_CONTENT[step] == nil then
        step = TutorialUI.FirstStep
    end
    self.step_ = step
    print("[Tutorial] 进入步骤: " .. step)
    if self.options_.onStepChanged then
        self.options_.onStepChanged(step)
    end
end

function Controller:Complete(skipped)
    if not self.active_ then
        return
    end
    self.active_ = false
    self.layer_:SetVisible(false)
    print(string.format(
        "[Tutorial] %s: kind=%s",
        skipped and "玩家关闭教程" or "教程完成",
        self.kind_
    ))
    if self.options_.onComplete then
        self.options_.onComplete(skipped == true)
    end
end

function Controller:IsActive()
    return self.active_ == true
end

function Controller:IsPointAllowed(x, y)
    if not self.active_ then
        return true
    end
    local rect = self.allowedRect_
    if not rect then
        return false
    end
    return x >= rect.x
        and x <= rect.x + rect.w
        and y >= rect.y
        and y <= rect.y + rect.h
end

function Controller:Notify(action, value)
    if not self.active_ then
        return
    end
    if action == "main_clicked" and self.step_ == "tap_main" then
        self:SetStep("earn_torque")
    elseif action == "upgrade_opened"
        and self.step_ == "open_upgrade" then
        self:SetStep("select_torque")
    elseif action == "torque_selected"
        and self.step_ == "select_torque" then
        self:SetStep("confirm_torque")
    elseif action == "torque_upgraded"
        and self.step_ == "confirm_torque" then
        self:SetStep("earn_gear")
    elseif action == "shop_drag_started"
        and value == "small"
        and self.step_ == "drag_small" then
        self:SetStep("place_small")
    elseif action == "gear_placed"
        and value == "small"
        and self.step_ == "place_small" then
        self:SetStep("generator_details")
    elseif action == "generator_details_opened"
        and self.step_ == "generator_details" then
        self:Complete(false)
    elseif action == "shop_drag_started"
        and value == "lubricant"
        and self.step_ == "lubricant_drag" then
        self:SetStep("lubricant_place")
    elseif action == "gear_placed"
        and value == "lubricant"
        and self.step_ == "lubricant_place" then
        self:Complete(false)
    end
end

function Controller:ResolveStep(context)
    if self.step_ == "tap_main" then
        return context.mainGearRect
    elseif self.step_ == "earn_torque" then
        if context.coins >= 25 then
            self:SetStep("open_upgrade")
            return self:ResolveStep(context)
        end
        return context.mainGearRect
    elseif self.step_ == "open_upgrade" then
        return WidgetRect(context.rightRailExpandButton)
    elseif self.step_ == "select_torque" then
        return WidgetRect(context.torqueUpgradeButton)
    elseif self.step_ == "confirm_torque" then
        if context.mainTorqueLevel > 0 then
            self:SetStep("earn_gear")
            return self:ResolveStep(context)
        end
        return WidgetRect(context.upgradeConfirmButton)
    elseif self.step_ == "earn_gear" then
        if context.coins >= 100 then
            self:SetStep("open_shop")
            return self:ResolveStep(context)
        end
        return context.mainGearRect
    elseif self.step_ == "open_shop" then
        local expandRect = WidgetRect(context.leftRailExpandButton)
        if expandRect then
            return expandRect
        end
        self:SetStep("drag_small")
        return self:ResolveStep(context)
    elseif self.step_ == "drag_small" then
        return WidgetRect(context.smallGearButton)
    elseif self.step_ == "place_small" then
        return context.mainGearDropRect
    elseif self.step_ == "generator_details" then
        return context.currencyGeneratorRect
    elseif self.step_ == "lubricant_earn" then
        if context.coins >= context.lubricantCost then
            self:SetStep("lubricant_open_shop")
            return self:ResolveStep(context)
        end
        return context.mainGearRect
    elseif self.step_ == "lubricant_open_shop" then
        local expandRect = WidgetRect(context.leftRailExpandButton)
        if expandRect then
            return expandRect
        end
        self:SetStep("lubricant_drag")
        return self:ResolveStep(context)
    elseif self.step_ == "lubricant_drag" then
        return WidgetRect(context.lubricantGearButton)
    elseif self.step_ == "lubricant_place" then
        return context.lubricantDropRect
    end
    return context.mainGearRect
end

function Controller:Update(_)
    if not self.active_ then
        return
    end
    local context = self.options_.getContext()
    if not context or context.homeVisible then
        self.layer_:SetVisible(false)
        return
    end
    self.layer_:SetVisible(true)

    if self.kind_ == "base"
        and self.step_ ~= "generator_details"
        and context.hasSmallGear then
        self:Complete(false)
        return
    end
    if self.kind_ == "base"
        and context.mainTorqueLevel > 0
        and (
            self.step_ == "tap_main"
            or self.step_ == "earn_torque"
            or self.step_ == "open_upgrade"
            or self.step_ == "select_torque"
            or self.step_ == "confirm_torque"
        ) then
        self:SetStep("earn_gear")
    end

    local rect = self:ResolveStep(context)
    if not rect then
        return
    end

    local screenWidth = math.max(1, context.screenWidth or 1)
    local screenHeight = math.max(1, context.screenHeight or 1)
    local padding = (
            self.step_ == "place_small"
            or self.step_ == "generator_details"
            or self.step_ == "lubricant_place"
        ) and 6 or 10
    local x = math.max(0, rect.x - padding)
    local y = math.max(0, rect.y - padding)
    local right = math.min(screenWidth, rect.x + rect.w + padding)
    local bottom = math.min(screenHeight, rect.y + rect.h + padding)
    local width = math.max(1, right - x)
    local height = math.max(1, bottom - y)
    self.allowedRect_ = { x = x, y = y, w = width, h = height }

    self.maskTop_:SetStyle({ left = 0, top = 0, width = screenWidth, height = y })
    self.maskLeft_:SetStyle({ left = 0, top = y, width = x, height = height })
    self.maskRight_:SetStyle({
        left = right,
        top = y,
        width = math.max(0, screenWidth - right),
        height = height,
    })
    self.maskBottom_:SetStyle({
        left = 0,
        top = bottom,
        width = screenWidth,
        height = math.max(0, screenHeight - bottom),
    })

    local progressText = ""
    if self.step_ == "earn_torque" then
        progressText = string.format("￥%d / ￥25", math.floor(context.coins))
    elseif self.step_ == "earn_gear" then
        progressText = string.format("余额 ￥%d / ￥100", math.floor(context.coins))
    elseif self.step_ == "lubricant_earn" then
        progressText = string.format(
            "余额 ￥%d / ￥%d",
            math.floor(context.coins),
            math.floor(context.lubricantCost)
        )
    end
    self.visual_:SetGuideData(
        { x = x, y = y, w = width, h = height },
        STEP_CONTENT[self.step_],
        screenWidth,
        screenHeight,
        progressText
    )
end

function TutorialUI.Create(options)
    options = options or {}
    local controller = setmetatable({}, Controller)
    controller.options_ = options
    controller.kind_ = options.kind or "base"
    controller.active_ = options.completed ~= true
    controller.step_ = STEP_CONTENT[options.initialStep]
            and options.initialStep
        or TutorialUI.FirstStep

    local function CreateMask()
        return UI.Panel {
            position = "absolute",
            left = 0,
            top = 0,
            width = 0,
            height = 0,
            backgroundColor = MASK_COLOR,
            pointerEvents = "auto",
        }
    end

    controller.maskTop_ = CreateMask()
    controller.maskLeft_ = CreateMask()
    controller.maskRight_ = CreateMask()
    controller.maskBottom_ = CreateMask()
    controller.visual_ = TutorialVisual {}

    local skipButton = UI.Button {
        text = controller.kind_ == "lubricant"
                and "关闭引导"
            or "跳过教程",
        position = "absolute",
        right = 18,
        top = 18,
        width = 112,
        height = 38,
        fontSize = 12,
        fontWeight = "bold",
        backgroundColor = { 20, 42, 55, 245 },
        hoverBackgroundColor = { 34, 72, 88, 255 },
        pressedBackgroundColor = { 10, 27, 36, 255 },
        borderColor = { 115, 196, 211, 255 },
        borderWidth = 2,
        borderRadius = 0,
        zIndex = 5,
        onClick = function()
            controller:Complete(true)
        end,
    }

    controller.layer_ = TutorialLayer {
        visible = controller.active_,
        children = {
            controller.maskTop_,
            controller.maskLeft_,
            controller.maskRight_,
            controller.maskBottom_,
            controller.visual_,
            skipButton,
        },
    }
    controller.layer_.controller_ = controller

    if controller.active_ then
        print(string.format(
            "[Tutorial] 教程已启动: kind=%s step=%s",
            controller.kind_,
            controller.step_
        ))
    end
    return controller
end

return TutorialUI
