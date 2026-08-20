local UI = require("urhox-libs/UI")
local ImageCache = require("urhox-libs/UI/Core/ImageCache")
local Widget = require("urhox-libs/UI/Core/Widget")

local HomeUI = {}

local DESIGN_WIDTH = 1920
local DESIGN_HEIGHT = 1080

local BACKGROUND_PATH =
    "image/home_landscape_factory_blueprint_bg_20260818094330.png"
local TITLE_FRAME_PATH = "image/home_title_frame_wide_v3_trimmed.png"
local FACTORY_BUTTON_PATH =
    "image/home_factory_button_panel_final.png"
local LEADERBOARD_BUTTON_PATH =
    "image/home_leaderboard_button_panel_final.png"
local FACTORY_ICON_PATH = "image/home_factory_entry_icon_20260818094329.png"
local LEADERBOARD_ICON_PATH =
    "image/home_leaderboard_entry_icon_20260818094318.png"
local LEADERBOARD_FRAME_PATH =
    "image/home_leaderboard_frame_wide_v2_trimmed.png"

local COLORS = {
    page = { 3, 11, 24, 255 },
    panel = { 5, 25, 47, 247 },
    panelAlternate = { 8, 39, 68, 247 },
    panelMe = { 12, 69, 93, 250 },
    cyan = { 57, 213, 255, 255 },
    cyanDark = { 8, 85, 122, 255 },
    gold = { 242, 176, 55, 255 },
    goldBright = { 255, 226, 139, 255 },
    goldDark = { 109, 62, 13, 255 },
    text = { 244, 248, 252, 255 },
    textMuted = { 161, 187, 205, 255 },
    border = { 6, 12, 19, 255 },
    divider = { 24, 112, 147, 205 },
}

local imageHandlesByContext_ = {}

local function GetImageHandle(vg, imagePath)
    local contextKey = tostring(vg)
    local contextHandles = imageHandlesByContext_[contextKey]
    if not contextHandles then
        contextHandles = {}
        imageHandlesByContext_[contextKey] = contextHandles
    end

    local handle = ImageCache.Get(imagePath)
    if handle and handle > 0 then
        contextHandles[imagePath] = handle
        return handle
    end

    contextHandles[imagePath] = nil
    print(string.format(
        "[HomeUI] ERROR: 首页素材加载失败，将在下一帧重试: path=%s",
        imagePath
    ))
    return 0
end

---@class HomeImageLayer : Widget
---@overload fun(props?: table): HomeImageLayer
local HomeImageLayer = Widget:Extend("HomeImageLayer")

function HomeImageLayer:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    self.imagePath_ = props.imagePath
    self.fit_ = props.fit or "stretch"
    self.sourceRatio_ = props.sourceRatio
    Widget.Init(self, props)
end

function HomeImageLayer:Render(vg)
    local imageHandle = GetImageHandle(vg, self.imagePath_)
    if not imageHandle or imageHandle <= 0 then
        return
    end

    local layout = self:GetAbsoluteLayout()
    local drawX, drawY = layout.x, layout.y
    local drawWidth, drawHeight = layout.w, layout.h
    local sourceRatio = self.sourceRatio_

    if sourceRatio and (self.fit_ == "cover" or self.fit_ == "contain") then
        local targetRatio = layout.w / math.max(1, layout.h)
        local useWidth = self.fit_ == "cover"
                and targetRatio > sourceRatio
            or self.fit_ == "contain"
                and targetRatio < sourceRatio
        if useWidth then
            drawHeight = layout.w / sourceRatio
            drawY = layout.y + (layout.h - drawHeight) * 0.5
        else
            drawWidth = layout.h * sourceRatio
            drawX = layout.x + (layout.w - drawWidth) * 0.5
        end
    end

    nvgSave(vg)
    nvgIntersectScissor(vg, layout.x, layout.y, layout.w, layout.h)
    nvgBeginPath(vg)
    nvgRect(vg, layout.x, layout.y, layout.w, layout.h)
    nvgFillPaint(vg, nvgImagePattern(
        vg,
        drawX,
        drawY,
        drawWidth,
        drawHeight,
        0,
        imageHandle,
        1
    ))
    nvgFill(vg)
    nvgRestore(vg)
end

---@class HomeRankBadge : Widget
---@overload fun(props?: table): HomeRankBadge
local HomeRankBadge = Widget:Extend("HomeRankBadge")

function HomeRankBadge:Init(props)
    props = props or {}
    props.pointerEvents = "none"
    Widget.Init(self, props)
end

function HomeRankBadge:Render(vg)
    local layout = self:GetAbsoluteLayout()
    local rank = tonumber(self.props.rank) or 0
    local cx = layout.x + layout.w * 0.5
    local cy = layout.y + layout.h * 0.5

    if rank > 3 then
        nvgFontFace(vg, "sans-bold")
        nvgFontSize(vg, 24)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(218, 228, 235, 255))
        nvgText(vg, cx, cy, tostring(rank))
        return
    end

    local colors = {
        {
            outer = nvgRGBA(250, 191, 54, 255),
            inner = nvgRGBA(103, 59, 9, 255),
            text = nvgRGBA(255, 239, 156, 255),
        },
        {
            outer = nvgRGBA(196, 216, 229, 255),
            inner = nvgRGBA(62, 78, 93, 255),
            text = nvgRGBA(250, 253, 255, 255),
        },
        {
            outer = nvgRGBA(202, 112, 53, 255),
            inner = nvgRGBA(91, 43, 22, 255),
            text = nvgRGBA(255, 210, 158, 255),
        },
    }
    local color = colors[rank]
    local outerRadius = math.min(layout.w, layout.h) * 0.42
    local rootRadius = outerRadius * 0.78
    local teeth = 12

    nvgBeginPath(vg)
    for index = 0, teeth * 2 - 1 do
        local angle = -math.pi * 0.5 + index * math.pi / teeth
        local radius = index % 2 == 0 and outerRadius or rootRadius
        local px = cx + math.cos(angle) * radius
        local py = cy + math.sin(angle) * radius
        if index == 0 then
            nvgMoveTo(vg, px, py)
        else
            nvgLineTo(vg, px, py)
        end
    end
    nvgClosePath(vg)
    nvgFillColor(vg, color.outer)
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(8, 13, 19, 255))
    nvgStrokeWidth(vg, 3)
    nvgStroke(vg)

    nvgBeginPath(vg)
    nvgCircle(vg, cx, cy, outerRadius * 0.62)
    nvgFillColor(vg, color.inner)
    nvgFill(vg)
    nvgStrokeColor(vg, color.outer)
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)

    nvgFontFace(vg, "sans-bold")
    nvgFontSize(vg, 22)
    nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    nvgFillColor(vg, color.text)
    nvgText(vg, cx, cy, tostring(rank))
end

local function CreateRankRow(entry, rowIndex)
    local rank = tonumber(entry.rank) or rowIndex
    local isMe = entry.isMe == true

    return UI.Panel {
        width = "100%",
        height = 64,
        minHeight = 64,
        flexDirection = "row",
        alignItems = "center",
        paddingHorizontal = 18,
        backgroundColor = isMe
                and COLORS.panelMe
            or (rowIndex % 2 == 0
                and COLORS.panelAlternate
            or COLORS.panel),
        borderBottomWidth = 1,
        borderBottomColor = COLORS.divider,
        pointerEvents = "none",
        children = {
            HomeRankBadge {
                rank = rank,
                width = 110,
                height = 58,
                flexShrink = 0,
            },
            UI.Label {
                text = entry.nickname or "齿轮工匠",
                flexGrow = 1,
                flexShrink = 1,
                fontSize = 18,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = isMe and COLORS.goldBright or COLORS.text,
            },
            UI.Label {
                text = entry.incomeText or "￥0/秒",
                width = 310,
                flexShrink = 0,
                fontSize = 18,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = COLORS.gold,
            },
        },
    }
end

local function CreateLeaderboardHeader()
    return UI.Panel {
        width = "100%",
        height = 54,
        flexDirection = "row",
        alignItems = "center",
        paddingHorizontal = 18,
        backgroundColor = { 4, 29, 53, 255 },
        borderTopWidth = 1,
        borderBottomWidth = 2,
        borderTopColor = COLORS.divider,
        borderBottomColor = COLORS.cyanDark,
        pointerEvents = "none",
        children = {
            UI.Label {
                text = "排名",
                width = 110,
                fontSize = 17,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = COLORS.gold,
            },
            UI.Label {
                text = "玩家",
                flexGrow = 1,
                fontSize = 17,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = COLORS.gold,
            },
            UI.Label {
                text = "每秒收益",
                width = 310,
                fontSize = 17,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = COLORS.gold,
            },
        },
    }
end

local function CreateEntryButton(options)
    return UI.Button {
        width = 650,
        height = 210,
        flexDirection = "row",
        alignItems = "center",
        padding = { 18, 42, 24, 36 },
        backgroundColor = { 0, 0, 0, 0 },
        hoverBackgroundColor = { 255, 255, 255, 14 },
        pressedBackgroundColor = { 0, 0, 0, 30 },
        borderWidth = 0,
        borderColor = { 0, 0, 0, 0 },
        borderRadius = 0,
        boxShadow = {
            { x = 10, y = 12, blur = 0, color = { 0, 0, 0, 118 } },
            { x = 0, y = 0, blur = 14, color = options.glowColor },
        },
        hoverBoxShadow = {
            { x = 10, y = 12, blur = 0, color = { 0, 0, 0, 126 } },
            { x = 0, y = 0, blur = 22, color = options.hoverGlowColor },
        },
        pressedBoxShadow = {
            { x = 5, y = 6, blur = 0, color = { 0, 0, 0, 142 } },
        },
        transition = "scale 0.12s easeOut",
        onClick = options.onClick,
        children = {
            HomeImageLayer {
                position = "absolute",
                left = 0,
                top = 0,
                width = 650,
                height = 210,
                imagePath = options.panelPath,
                fit = "contain",
                sourceRatio = options.panelRatio,
            },
            UI.Panel {
                position = "absolute",
                left = 48,
                top = 30,
                width = 142,
                height = 142,
                flexShrink = 0,
                pointerEvents = "none",
                children = {
                    HomeImageLayer {
                        position = "absolute",
                        left = 0,
                        top = 0,
                        width = 142,
                        height = 142,
                        imagePath = options.iconPath,
                        fit = "contain",
                        sourceRatio = 1,
                    },
                },
            },
            UI.Panel {
                position = "absolute",
                left = 214,
                top = 42,
                width = 394,
                height = 116,
                justifyContent = "center",
                alignItems = "center",
                pointerEvents = "none",
                children = {
                    UI.Label {
                        text = options.text,
                        width = "100%",
                        height = 72,
                        fontSize = 40,
                        fontWeight = "bold",
                        letterSpacing = 5,
                        textAlign = "center",
                        fontColor = COLORS.text,
                        textStroke = {
                            width = 3,
                            color = { 1, 5, 10, 255 },
                        },
                        textShadow = {
                            offsetX = 4,
                            offsetY = 6,
                            blur = 0,
                            color = { 0, 0, 0, 220 },
                        },
                        pointerEvents = "none",
                    },
                },
            },
        },
    }
end

---@param callbacks table
---@return table
function HomeUI.Create(callbacks)
    callbacks = callbacks or {}
    local layoutWidth = math.max(1, callbacks.layoutWidth or DESIGN_WIDTH)
    local layoutHeight = math.max(1, callbacks.layoutHeight or DESIGN_HEIGHT)

    local leaderboardStatusLabel = UI.Label {
        text = "正在同步云端前100名…",
        width = "100%",
        paddingVertical = 20,
        fontSize = 19,
        fontWeight = "bold",
        textAlign = "center",
        fontColor = COLORS.textMuted,
        pointerEvents = "none",
    }

    local leaderboardRows = UI.Panel {
        width = "100%",
        children = {},
    }

    local leaderboardContent = UI.Panel {
        width = "100%",
        minHeight = 510,
        children = {
            leaderboardStatusLabel,
            leaderboardRows,
        },
    }

    local leaderboardFooterLabel = UI.Label {
        text = "滑动查看前100名",
        width = "100%",
        height = 36,
        fontSize = 15,
        fontWeight = "bold",
        letterSpacing = 2,
        textAlign = "center",
        fontColor = COLORS.textMuted,
        pointerEvents = "none",
    }

    ---@type Widget
    local homePage = nil
    ---@type Widget
    local leaderboardPage = nil

    local function ShowHomePage()
        homePage:SetVisible(true)
        leaderboardPage:SetVisible(false)
        print("[HomeUI] 返回首页双入口")
    end

    local function ShowLeaderboardPage()
        homePage:SetVisible(false)
        leaderboardPage:SetVisible(true)
        if callbacks.onOpenLeaderboard then
            callbacks.onOpenLeaderboard()
        end
        print("[HomeUI] 打开排行榜页面")
    end

    local factoryButton = CreateEntryButton({
        text = "齿轮工厂",
        panelPath = FACTORY_BUTTON_PATH,
        panelRatio = 991 / 351,
        iconPath = FACTORY_ICON_PATH,
        backgroundColor = { 93, 52, 14, 252 },
        hoverBackgroundColor = { 132, 75, 19, 255 },
        pressedBackgroundColor = { 61, 32, 9, 255 },
        glowColor = { 242, 164, 46, 48 },
        hoverGlowColor = { 255, 191, 71, 92 },
        onClick = function()
            print("[HomeUI] 点击齿轮工厂入口")
            if callbacks.onEnterFactory then
                callbacks.onEnterFactory()
            end
        end,
    })

    local leaderboardButton = CreateEntryButton({
        text = "排行榜",
        panelPath = LEADERBOARD_BUTTON_PATH,
        panelRatio = 1023 / 378,
        iconPath = LEADERBOARD_ICON_PATH,
        backgroundColor = { 6, 53, 86, 252 },
        hoverBackgroundColor = { 9, 82, 126, 255 },
        pressedBackgroundColor = { 3, 34, 58, 255 },
        glowColor = { 45, 205, 255, 45 },
        hoverGlowColor = { 66, 220, 255, 88 },
        onClick = ShowLeaderboardPage,
    })

    homePage = UI.Panel {
        position = "absolute",
        left = 0,
        top = 0,
        width = DESIGN_WIDTH,
        height = DESIGN_HEIGHT,
        pointerEvents = "box-none",
        children = {
            HomeImageLayer {
                position = "absolute",
                left = 525,
                top = 18,
                width = 870,
                height = 238,
                imagePath = TITLE_FRAME_PATH,
            },
            UI.Label {
                position = "absolute",
                left = 645,
                top = 64,
                width = 630,
                height = 112,
                text = "齿轮工坊",
                fontSize = 58,
                fontWeight = "bold",
                letterSpacing = 8,
                textAlign = "center",
                fontColor = COLORS.goldBright,
                textStroke = { width = 4, color = { 45, 23, 6, 255 } },
                textShadow = {
                    offsetX = 6,
                    offsetY = 8,
                    blur = 0,
                    color = { 0, 0, 0, 190 },
                },
                pointerEvents = "none",
            },
            UI.Panel {
                position = "absolute",
                left = 285,
                top = 816,
                width = 1350,
                height = 190,
                flexDirection = "row",
                gap = 50,
                pointerEvents = "box-none",
                children = {
                    factoryButton,
                    leaderboardButton,
                },
            },
        },
    }

    local leaderboardScroll = UI.ScrollView {
        width = "100%",
        flexGrow = 1,
        flexBasis = 0,
        scrollX = false,
        scrollY = true,
        showScrollbar = false,
        bounces = true,
        backgroundColor = COLORS.panel,
        children = { leaderboardContent },
    }

    leaderboardPage = UI.Panel {
        visible = false,
        position = "absolute",
        left = 0,
        top = 0,
        width = DESIGN_WIDTH,
        height = DESIGN_HEIGHT,
        pointerEvents = "box-none",
        children = {
            UI.Panel {
                position = "absolute",
                left = 165,
                top = 70,
                width = 1590,
                height = 930,
                backgroundColor = { 3, 17, 33, 248 },
                borderWidth = 4,
                borderColor = COLORS.border,
                borderRadius = 0,
                boxShadow = {
                    { x = 12, y = 14, blur = 0, color = { 0, 0, 0, 130 } },
                },
                overflow = "hidden",
                children = {
                    HomeImageLayer {
                        position = "absolute",
                        left = 0,
                        top = 0,
                        width = 1590,
                        height = 930,
                        imagePath = LEADERBOARD_FRAME_PATH,
                    },
                    UI.Panel {
                        position = "absolute",
                        left = 135,
                        top = 108,
                        width = 1320,
                        height = 720,
                        backgroundColor = { 3, 21, 40, 244 },
                        borderWidth = 2,
                        borderColor = COLORS.cyanDark,
                        borderRadius = 0,
                        overflow = "hidden",
                        children = {
                            UI.Panel {
                                width = "100%",
                                height = 104,
                                flexDirection = "row",
                                alignItems = "center",
                                paddingHorizontal = 22,
                                backgroundColor = { 6, 43, 72, 250 },
                                borderBottomWidth = 4,
                                borderBottomColor = COLORS.goldDark,
                                children = {
                                    UI.Button {
                                        text = "返回",
                                        width = 150,
                                        height = 56,
                                        fontSize = 19,
                                        fontWeight = "bold",
                                        backgroundColor = { 25, 58, 76, 255 },
                                        hoverBackgroundColor = { 38, 87, 111, 255 },
                                        pressedBackgroundColor = { 14, 37, 51, 255 },
                                        borderWidth = 3,
                                        borderColor = COLORS.border,
                                        borderRadius = 0,
                                        onClick = ShowHomePage,
                                    },
                                    UI.Label {
                                        text = "排行榜",
                                        flexGrow = 1,
                                        height = 68,
                                        fontSize = 40,
                                        fontWeight = "bold",
                                        letterSpacing = 7,
                                        textAlign = "center",
                                        fontColor = COLORS.goldBright,
                                        textStroke = {
                                            width = 2,
                                            color = { 40, 20, 6, 255 },
                                        },
                                        pointerEvents = "none",
                                    },
                                    UI.Panel {
                                        width = 150,
                                        height = 1,
                                        pointerEvents = "none",
                                    },
                                },
                            },
                            CreateLeaderboardHeader(),
                            leaderboardScroll,
                            leaderboardFooterLabel,
                        },
                    },
                },
            },
        },
    }

    local designScale = math.min(
        layoutWidth / DESIGN_WIDTH,
        layoutHeight / DESIGN_HEIGHT
    )
    local designOffsetX = (layoutWidth - DESIGN_WIDTH * designScale) * 0.5
    local designOffsetY = (layoutHeight - DESIGN_HEIGHT * designScale) * 0.5

    local designSurface = UI.Panel {
        position = "absolute",
        left = designOffsetX,
        top = designOffsetY,
        width = DESIGN_WIDTH,
        height = DESIGN_HEIGHT,
        scale = designScale,
        transformOrigin = "top-left",
        pointerEvents = "box-none",
        children = {
            homePage,
            leaderboardPage,
        },
    }

    local overlay = UI.Panel {
        id = "homeOverlay",
        visible = callbacks.visible ~= false,
        position = "absolute",
        top = 0,
        left = 0,
        width = layoutWidth,
        height = layoutHeight,
        backgroundColor = COLORS.page,
        overflow = "hidden",
        pointerEvents = "auto",
        zIndex = 10000,
        children = {
            HomeImageLayer {
                position = "absolute",
                left = 0,
                top = 0,
                width = layoutWidth,
                height = layoutHeight,
                imagePath = BACKGROUND_PATH,
                fit = "cover",
                sourceRatio = DESIGN_WIDTH / DESIGN_HEIGHT,
            },
            designSurface,
        },
    }

    print(string.format(
        "[HomeUI] 横版双入口首页创建完成: layout=%.0fx%.0f scale=%.4f offset=(%.1f, %.1f)",
        layoutWidth,
        layoutHeight,
        designScale,
        designOffsetX,
        designOffsetY
    ))

    return {
        overlay = overlay,
        leaderboardScroll = leaderboardScroll,
        setVisible = function(visible)
            overlay:SetVisible(visible == true)
            if visible == true then
                ShowHomePage()
            end
        end,
        setAssetText = function(_)
        end,
        setLeaderboardStatus = function(text)
            leaderboardStatusLabel:SetText(text or "暂无排行数据")
            leaderboardFooterLabel:SetText(text or "云端排行")
        end,
        setLeaderboard = function(entries)
            leaderboardRows:ClearChildren()
            if type(entries) ~= "table" or #entries == 0 then
                leaderboardStatusLabel:SetText("暂无排行数据")
                leaderboardFooterLabel:SetText("暂无排行")
                return
            end
            leaderboardStatusLabel:SetText("")
            for index, entry in ipairs(entries) do
                leaderboardRows:AddChild(CreateRankRow(entry, index))
            end
            leaderboardFooterLabel:SetText(string.format(
                "已载入 %d / 100",
                math.min(100, #entries)
            ))
        end,
    }
end

return HomeUI
