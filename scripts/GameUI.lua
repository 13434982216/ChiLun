local UI = require("urhox-libs/UI")

local GameUI = {}

local GEAR_CARD_IMAGES = {
    small = "image/gear_small_comic_exact.png",
    medium = "image/gear_medium_comic_exact.png",
    large = "image/gear_large_comic_exact.png",
    compound = "image/gear_compound_comic_exact.png",
    momma = "image/gear_momma_comic_exact.png",
}

local function CreateGearShopCard(options)
    local priceLabel = UI.Label {
        text = options.priceText,
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 255, 203, 92, 255 },
        pointerEvents = "none",
    }
    local card = UI.Card {
        variant = "outlined",
        clickable = true,
        hoverable = true,
        height = 78,
        flexGrow = 1,
        flexBasis = 0,
        padding = 7,
        borderRadius = 9,
        borderWidth = 1,
        borderColor = { 111, 130, 145, 210 },
        backgroundColor = { 23, 31, 38, 248 },
        flexDirection = "row",
        alignItems = "center",
        gap = 7,
        children = {
            UI.Panel {
                width = 58,
                height = 58,
                flexShrink = 0,
                backgroundImage = options.image,
                backgroundFit = "contain",
                pointerEvents = "none",
            },
            UI.Panel {
                flexGrow = 1,
                flexShrink = 1,
                gap = 2,
                pointerEvents = "none",
                children = {
                    UI.Label {
                        text = options.model,
                        fontSize = 12,
                        fontWeight = "bold",
                        fontColor = { 226, 234, 239, 255 },
                        pointerEvents = "none",
                    },
                    UI.Label {
                        text = options.teeth,
                        fontSize = 10,
                        fontColor = { 144, 164, 176, 245 },
                        pointerEvents = "none",
                    },
                    priceLabel,
                },
            },
        },
    }
    card.OnPointerDown = function(_, event)
        if not card.props.clickable or not event:IsPrimaryAction() then
            return
        end
        card:SetState({ pressed = true })
    end
    card.props.onPointerMove = function()
    end
    card.OnPointerUp = function()
        card:SetState({ pressed = false })
    end
    card.props.shopGearType = options.gearType
    return card, priceLabel
end

---@param callbacks table
---@return table
function GameUI.Create(callbacks)
    local coinLabel = UI.Label {
        text = "金币  0",
        fontSize = 20,
        fontWeight = "bold",
        fontColor = { 255, 224, 130, 255 },
    }

    local clickValueLabel = UI.Label {
        text = "每次点击  +1",
        fontSize = 11,
        fontColor = { 206, 213, 228, 230 },
    }

    local revenueLabel = UI.Label {
        text = "实时收益  $0.00/s",
        fontSize = 11,
        fontColor = { 113, 232, 163, 245 },
    }

    local essenceLabel = UI.Label {
        text = "齿轮精华  0",
        fontSize = 12,
        fontColor = { 130, 208, 255, 245 },
    }

    local powerStatusLabel = UI.Label {
        text = "待解锁自动运转\n当前负载 / 总扭矩  0 / 24",
        fontSize = 10,
        lineHeight = 1.25,
        fontColor = { 213, 221, 236, 245 },
    }

    local loadGaugeLabel = UI.Label {
        text = "负载占用  0%",
        fontSize = 10,
        fontWeight = "bold",
        fontColor = { 124, 207, 231, 245 },
        pointerEvents = "none",
    }

    local loadProgressBar = UI.ProgressBar {
        value = 0,
        max = 1,
        height = 10,
        showLabel = false,
        variant = "success",
        trackColor = { 11, 19, 25, 230 },
        trackBorderWidth = 1,
        trackBorderColor = { 88, 119, 132, 190 },
        fillColor = { 84, 215, 153, 255 },
        transition = "value 0.2s easeOut",
        pointerEvents = "none",
    }

    local levelLabel = UI.Label {
        text = "点击收益等级  Lv.1",
        fontSize = 14,
        fontColor = { 236, 239, 247, 255 },
    }

    local shopInfoLabel = UI.Label {
        text = "已购买 0  ·  已连通 0  ·  每颗 +1/秒",
        fontSize = 12,
        fontColor = { 170, 181, 202, 235 },
    }

    local upgradeButton = UI.Button {
        text = "升级手动点击  10 金币",
        variant = "secondary",
        height = 42,
        flexShrink = 1,
        onClick = function()
            callbacks.upgradeClickValue()
        end,
    }

    local mainTorqueUpgradeButton = UI.Button {
        text = "扭矩上限 Lv.0  25金币",
        variant = "primary",
        height = 42,
        flexShrink = 1,
        onClick = function()
            callbacks.upgradeMainTorque()
        end,
    }

    local mainCircleIncomeUpgradeButton = UI.Button {
        text = "单圈收益 Lv.0  40金币",
        variant = "secondary",
        height = 42,
        flexShrink = 1,
        onClick = function()
            callbacks.upgradeMainCircleIncome()
        end,
    }

    local buySmallGearButton, buySmallGearPriceLabel = CreateGearShopCard {
        model = "S-16  小型",
        teeth = "16 齿 · 轻载",
        priceText = "15 金币",
        gearType = "small",
        image = GEAR_CARD_IMAGES.small,
        onDragStart = callbacks.shopGearDragStart,
        onDragMove = callbacks.shopGearDragMove,
        onDragEnd = callbacks.shopGearDragEnd,
        onDragCancel = callbacks.shopGearDragCancel,
    }

    local buyMediumGearButton, buyMediumGearPriceLabel = CreateGearShopCard {
        model = "M-32  中型",
        teeth = "32 齿 · 标准",
        priceText = "45 金币",
        gearType = "medium",
        image = GEAR_CARD_IMAGES.medium,
        onDragStart = callbacks.shopGearDragStart,
        onDragMove = callbacks.shopGearDragMove,
        onDragEnd = callbacks.shopGearDragEnd,
        onDragCancel = callbacks.shopGearDragCancel,
    }

    local buyLargeGearButton, buyLargeGearPriceLabel = CreateGearShopCard {
        model = "L-48  大型",
        teeth = "48 齿 · 重载",
        priceText = "100 金币",
        gearType = "large",
        image = GEAR_CARD_IMAGES.large,
        onDragStart = callbacks.shopGearDragStart,
        onDragMove = callbacks.shopGearDragMove,
        onDragEnd = callbacks.shopGearDragEnd,
        onDragCancel = callbacks.shopGearDragCancel,
    }

    local buyCompoundGearButton, buyCompoundGearPriceLabel = CreateGearShopCard {
        model = "C-32/12  双层",
        teeth = "32/12 齿 · 复合轴",
        priceText = "160 金币",
        gearType = "compound",
        image = GEAR_CARD_IMAGES.compound,
        onDragStart = callbacks.shopGearDragStart,
        onDragMove = callbacks.shopGearDragMove,
        onDragEnd = callbacks.shopGearDragEnd,
        onDragCancel = callbacks.shopGearDragCancel,
    }

    local buyMommaGearButton, buyMommaGearPriceLabel = CreateGearShopCard {
        model = "MG-48/16  母齿轮",
        teeth = "48/16 齿 · 固定 x11.25",
        priceText = "2500 金币",
        gearType = "momma",
        image = GEAR_CARD_IMAGES.momma,
        onDragStart = callbacks.shopGearDragStart,
        onDragMove = callbacks.shopGearDragMove,
        onDragEnd = callbacks.shopGearDragEnd,
        onDragCancel = callbacks.shopGearDragCancel,
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
        height = 38,
        flexShrink = 0,
        onClick = function()
            callbacks.claimMommaFactoryGear()
        end,
    }

    local autoDriveButton = UI.Button {
        text = "自动运转：扭矩 Lv.3 解锁",
        variant = "secondary",
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
        fontSize = 16,
        fontWeight = "bold",
        fontColor = { 255, 229, 145, 255 },
    }

    local gearDetailsStatusLabel = UI.Label {
        text = "未连接动力",
        fontSize = 12,
        fontColor = { 135, 230, 174, 255 },
    }

    local gearDetailsStatsLabel = UI.Label {
        text = "齿数  0\n层级  0 · 齿轮负载  0\n层负载  0 · 压速系数 x0\n整体轴转速  0 RPM\n轴上传入扭矩  0\n每秒收益  0 金币",
        fontSize = 12,
        lineHeight = 1.35,
        fontColor = { 226, 231, 241, 255 },
        flexShrink = 1,
    }

    local gearDetailsUpgradeLabel = UI.Label {
        text = "Lv.1",
        fontSize = 11,
        fontColor = { 165, 177, 199, 235 },
        flexShrink = 1,
    }

    local gearDetailsEssenceLabel = UI.Label {
        text = "永久精华  0 · 飞升 0 次",
        fontSize = 11,
        fontWeight = "bold",
        fontColor = { 130, 208, 255, 245 },
        flexShrink = 1,
    }

    local gearUpgradeButton = UI.Button {
        text = "升级此齿轮",
        variant = "primary",
        height = 42,
        alignSelf = "stretch",
        onClick = function()
            callbacks.upgradeSelectedGear()
        end,
    }

    local gearDetailsCloseButton = UI.Button {
        text = "关闭详情",
        variant = "secondary",
        height = 36,
        alignSelf = "stretch",
        onClick = function()
            callbacks.closeGearDetails()
        end,
    }

    local gearDetailsPanel = UI.Panel {
        id = "gearDetailsPanel",
        visible = false,
        position = "absolute",
        top = 82,
        right = 8,
        width = 230,
        padding = 12,
        gap = 7,
        backgroundColor = { 24, 30, 43, 248 },
        borderRadius = 14,
        borderWidth = 2,
        borderColor = { 255, 220, 122, 175 },
        pointerEvents = "auto",
        children = {
            gearDetailsTitleLabel,
            gearDetailsStatusLabel,
            gearDetailsStatsLabel,
            gearDetailsUpgradeLabel,
            gearDetailsEssenceLabel,
            gearUpgradeButton,
            gearDetailsCloseButton,
        },
    }

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

    local unlockMapButton = UI.Button {
        text = "解锁子地图",
        variant = "secondary",
        height = 42,
        alignSelf = "stretch",
        onClick = function()
            callbacks.purchaseMetaUnlock("subMaps", "scrapyard")
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

    globalUpgradePanel = UI.Panel {
        visible = false,
        position = "absolute",
        top = "12%",
        left = "8%",
        right = "8%",
        height = 520,
        padding = 16,
        gap = 9,
        backgroundColor = { 24, 30, 43, 252 },
        borderRadius = 16,
        borderWidth = 2,
        borderColor = { 111, 211, 167, 180 },
        pointerEvents = "auto",
        children = {
            UI.Label {
                text = "全局工坊升级",
                fontSize = 18,
                fontWeight = "bold",
                fontColor = { 255, 225, 132, 255 },
            },
            UI.Label {
                text = "永久强化对所有轮回生效，消耗齿轮精华",
                fontSize = 11,
                fontColor = { 160, 177, 202, 235 },
            },
            globalUpgradeSummaryLabel,
            globalIncomeUpgradeButton,
            decayUpgradeButton,
            offlineUpgradeButton,
            unlockMapButton,
            unlockBuildingButton,
            globalUpgradeCloseButton,
        },
    }

    local globalUpgradeOpenButton = UI.Button {
        text = "精华永久强化",
        variant = "primary",
        height = 38,
        flexGrow = 1,
        onClick = function()
            globalUpgradePanel:SetVisible(true)
            callbacks.refreshGlobalUpgradeUI()
        end,
    }

    local ascensionOpenButton = UI.Button {
        text = "飞升重构",
        variant = "secondary",
        height = 38,
        flexGrow = 1,
        onClick = function()
            callbacks.openAscensionPanel()
        end,
    }

    local essenceOpenButton = UI.Button {
        text = "精华强化",
        variant = "secondary",
        height = 28,
        paddingLeft = 10,
        paddingRight = 10,
        flexShrink = 0,
        onClick = function()
            globalUpgradePanel:SetVisible(true)
            callbacks.refreshGlobalUpgradeUI()
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
        text = "本局累计 0 金币",
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
    ascensionPanel = UI.Panel {
        visible = false,
        position = "absolute",
        top = "23%",
        left = "8%",
        right = "8%",
        padding = 18,
        gap = 11,
        backgroundColor = { 23, 30, 45, 253 },
        borderRadius = 18,
        borderWidth = 2,
        borderColor = { 116, 205, 255, 210 },
        pointerEvents = "auto",
        children = {
            UI.Label {
                text = "飞升重构",
                fontSize = 20,
                fontWeight = "bold",
                textAlign = "center",
                fontColor = { 255, 226, 139, 255 },
            },
            ascensionRewardLabel,
            ascensionProgressLabel,
            UI.Label {
                text = "将清空：本局金币、摆放齿轮、主齿轮临时等级、单齿轮等级、自动驱动。\n永久保留：齿轮精华、精华强化、子地图与建筑权限。",
                fontSize = 11,
                lineHeight = 1.45,
                fontColor = { 184, 196, 215, 245 },
            },
            UI.Panel {
                flexDirection = "row",
                gap = 8,
                children = {
                    ascensionCloseButton,
                    ascensionConfirmButton,
                },
            },
        },
    }

    local ascensionToastLabel = UI.Label {
        text = "",
        visible = false,
        position = "absolute",
        top = "32%",
        left = "8%",
        right = "8%",
        padding = 14,
        borderRadius = 14,
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
        text = "领取离线金币",
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
        borderRadius = 18,
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
        },
    }

    local transmissionShopPanel = UI.Panel {
        visible = false,
        flexDirection = "row",
        gap = 7,
        pointerEvents = "auto",
        children = {
            buyCompoundGearButton,
            buyMommaGearButton,
        },
    }

    local factoryShopPanel = UI.Panel {
        visible = false,
        padding = 8,
        gap = 6,
        borderRadius = 10,
        borderWidth = 1,
        borderColor = { 74, 150, 118, 190 },
        backgroundColor = { 19, 42, 39, 242 },
        pointerEvents = "auto",
        children = {
            factoryStatusLabel,
            factoryClaimButton,
        },
    }

    local upgradeShopPanel = UI.Panel {
        visible = false,
        gap = 6,
        pointerEvents = "auto",
        children = {
            autoDriveButton,
            levelLabel,
            UI.Panel {
                flexDirection = "row",
                gap = 6,
                pointerEvents = "auto",
                children = {
                    mainTorqueUpgradeButton,
                    mainCircleIncomeUpgradeButton,
                    upgradeButton,
                },
            },
            UI.Panel {
                flexDirection = "row",
                gap = 7,
                pointerEvents = "auto",
                children = {
                    globalUpgradeOpenButton,
                    ascensionOpenButton,
                },
            },
        },
    }

    local shopTabs = {
        basic = basicShopPanel,
        transmission = transmissionShopPanel,
        factory = factoryShopPanel,
        upgrade = upgradeShopPanel,
    }
    local shopTabButtons = {}
    local activeShopTab = "basic"
    local shopExpanded = false
    ---@type Widget
    local shopBody
    ---@type Button
    local shopToggleButton
    ---@type Widget
    local shopToggleDock

    local function SetShopTab(tabId)
        activeShopTab = tabId
        for id, panel in pairs(shopTabs) do
            panel:SetVisible(id == tabId)
        end
        for id, button in pairs(shopTabButtons) do
            button:SetStyle({
                variant = id == tabId and "primary" or "secondary",
            })
            button:SetOpacity(id == tabId and 1 or 0.72)
        end
    end

    local function CreateShopTabButton(tabId, text)
        local button = UI.Button {
            text = text,
            variant = tabId == activeShopTab and "primary" or "secondary",
            height = 32,
            flexGrow = 1,
            flexBasis = 0,
            fontSize = 11,
            paddingLeft = 6,
            paddingRight = 6,
            onClick = function()
                SetShopTab(tabId)
            end,
        }
        shopTabButtons[tabId] = button
        return button
    end

    local basicTabButton = CreateShopTabButton("basic", "基础齿轮")
    local transmissionTabButton = CreateShopTabButton("transmission", "变速齿轮")
    local factoryTabButton = CreateShopTabButton("factory", "巨型工厂")
    local upgradeTabButton = CreateShopTabButton("upgrade", "工坊强化")

    local function SetShopExpanded(expanded)
        shopExpanded = expanded
        shopBody:SetVisible(expanded)
        shopToggleButton:SetText(expanded and "收起商店  ▼" or "展开商店  ▲")
        shopToggleDock:SetStyle({
            bottom = expanded and 281 or 68,
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
        height = 196,
        flexShrink = 0,
        gap = 7,
        pointerEvents = "auto",
        children = {
            UI.Panel {
                flexDirection = "row",
                gap = 5,
                pointerEvents = "auto",
                children = {
                    basicTabButton,
                    transmissionTabButton,
                    factoryTabButton,
                    upgradeTabButton,
                },
            },
            basicShopPanel,
            transmissionShopPanel,
            factoryShopPanel,
            upgradeShopPanel,
        },
    }

    local shopDrawer = UI.Panel {
        position = "absolute",
        left = 16,
        right = 16,
        bottom = 18,
        padding = 10,
        gap = 7,
        backgroundColor = { 27, 32, 46, 248 },
        borderRadius = 16,
        borderWidth = 1,
        borderColor = { 226, 174, 74, 115 },
        pointerEvents = "auto",
        children = {
            UI.Panel {
                flexDirection = "row",
                alignItems = "center",
                gap = 8,
                pointerEvents = "auto",
                children = {
                    UI.Label {
                        text = "齿轮商店 · 拖入画布购买",
                        fontSize = 14,
                        fontWeight = "bold",
                        fontColor = { 255, 220, 127, 255 },
                        flexShrink = 0,
                    },
                    UI.Panel {
                        flexGrow = 1,
                        flexShrink = 1,
                        pointerEvents = "none",
                        children = { shopInfoLabel },
                    },
                },
            },
            shopBody,
        },
    }

    local root = UI.Panel {
        id = "gameUI",
        width = "100%",
        height = "100%",
        pointerEvents = "box-none",
        children = {
            canvasInputArea,
            UI.SafeAreaView {
                width = "100%",
                height = "100%",
                nativeMenuInset = true,
                pointerEvents = "box-none",
                children = {
                    UI.Panel {
                        position = "absolute",
                        top = 10,
                        left = 12,
                        right = 12,
                        padding = 10,
                        gap = 4,
                        backgroundColor = { 27, 32, 46, 238 },
                        borderRadius = 14,
                        borderWidth = 1,
                        borderColor = { 226, 174, 74, 110 },
                        pointerEvents = "box-none",
                        children = {
                            UI.Panel {
                                flexDirection = "row",
                                alignItems = "center",
                                justifyContent = "space-between",
                                gap = 8,
                                pointerEvents = "auto",
                                children = {
                                    UI.Panel {
                                        flexGrow = 1,
                                        flexShrink = 1,
                                        gap = 1,
                                        pointerEvents = "none",
                                        children = {
                                            UI.Label {
                                                text = callbacks.title,
                                                fontSize = 10,
                                                fontColor = { 173, 183, 204, 220 },
                                            },
                                            coinLabel,
                                            clickValueLabel,
                                        },
                                    },
                                    UI.Panel {
                                        flexGrow = 1,
                                        flexShrink = 1,
                                        alignItems = "flex-end",
                                        gap = 2,
                                        pointerEvents = "auto",
                                        children = {
                                            revenueLabel,
                                            essenceLabel,
                                            essenceOpenButton,
                                        },
                                    },
                                },
                            },
                            powerStatusLabel,
                            UI.Panel {
                                flexDirection = "row",
                                alignItems = "center",
                                gap = 8,
                                pointerEvents = "none",
                                children = {
                                    UI.Panel {
                                        flexGrow = 1,
                                        flexShrink = 1,
                                        children = { loadProgressBar },
                                    },
                                    loadGaugeLabel,
                                },
                            },
                        },
                    },
                    shopDrawer,
                    shopToggleDock,
                },
            },
            gearDetailsPanel,
            globalUpgradePanel,
            ascensionPanel,
            offlineRewardPanel,
            ascensionToastLabel,
        },
    }

    UI.SetRoot(root)

    return {
        root = root,
        coinLabel = coinLabel,
        essenceLabel = essenceLabel,
        clickValueLabel = clickValueLabel,
        revenueLabel = revenueLabel,
        powerStatusLabel = powerStatusLabel,
        loadGaugeLabel = loadGaugeLabel,
        loadProgressBar = loadProgressBar,
        levelLabel = levelLabel,
        shopInfoLabel = shopInfoLabel,
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
        gearDetailsCloseButton = gearDetailsCloseButton,
        globalUpgradePanel = globalUpgradePanel,
        globalUpgradeSummaryLabel = globalUpgradeSummaryLabel,
        globalIncomeUpgradeButton = globalIncomeUpgradeButton,
        decayUpgradeButton = decayUpgradeButton,
        offlineUpgradeButton = offlineUpgradeButton,
        unlockMapButton = unlockMapButton,
        unlockBuildingButton = unlockBuildingButton,
        globalUpgradeOpenButton = globalUpgradeOpenButton,
        globalUpgradeCloseButton = globalUpgradeCloseButton,
        ascensionPanel = ascensionPanel,
        ascensionOpenButton = ascensionOpenButton,
        ascensionRewardLabel = ascensionRewardLabel,
        ascensionProgressLabel = ascensionProgressLabel,
        ascensionConfirmButton = ascensionConfirmButton,
        ascensionToastLabel = ascensionToastLabel,
        offlineRewardPanel = offlineRewardPanel,
        offlineRewardLabel = offlineRewardLabel,
        claimOfflineButton = claimOfflineButton,
        canvasInputArea = canvasInputArea,
    }
end

return GameUI
