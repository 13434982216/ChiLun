local UI = require("urhox-libs/UI")
local GameUI = require("GameUI")
local SaveSystem = require("SaveSystem")
local GearSystem = require("GearSystem")
local GearRenderer = require("GearRenderer")
local GearDefinitions = require("GearDefinitions")
local MetaProgression = require("MetaProgression")

local CONFIG = {
    Title = "齿轮工坊",
    AutoSaveDelay = 0.35,
    IncomeSaveDelay = 5.0,
    DragThreshold = 10,
}

---@type NVGContextWrapper
local vg_
---@type Widget
local uiRoot_
---@type Label
local coinLabel_
---@type Label
local clickValueLabel_
---@type Label
local revenueLabel_
---@type Label
local levelLabel_
---@type Label
local shopInfoLabel_
---@type Button
local upgradeButton_
---@type Card
local buySmallGearButton_
---@type Label
local buySmallGearPriceLabel_
---@type Card
local buyMediumGearButton_
---@type Label
local buyMediumGearPriceLabel_
---@type Card
local buyLargeGearButton_
---@type Label
local buyLargeGearPriceLabel_
---@type Card
local buyCompoundGearButton_
---@type Label
local buyCompoundGearPriceLabel_
---@type Card
local buyMommaGearButton_
---@type Label
local buyMommaGearPriceLabel_
---@type Label
local factoryStatusLabel_
---@type Button
local factoryClaimButton_
---@type Button
local autoDriveButton_
---@type Button
local mainTorqueUpgradeButton_
---@type Button
local mainCircleIncomeUpgradeButton_
---@type Label
local powerStatusLabel_
---@type Label
local loadGaugeLabel_
---@type ProgressBar
local loadProgressBar_
---@type Label
local essenceLabel_
---@type Widget
local gearDetailsPanel_
---@type Label
local gearDetailsTitleLabel_
---@type Label
local gearDetailsStatusLabel_
---@type Label
local gearDetailsStatsLabel_
---@type Label
local gearDetailsUpgradeLabel_
---@type Label
local gearDetailsEssenceLabel_
---@type Button
local gearUpgradeButton_
---@type Button
local gearDetailsCloseButton_
---@type Widget
local globalUpgradePanel_
---@type Label
local globalUpgradeSummaryLabel_
---@type Button
local globalIncomeUpgradeButton_
---@type Button
local decayUpgradeButton_
---@type Button
local offlineUpgradeButton_
---@type Button
local globalUpgradeOpenButton_
---@type Button
local globalUpgradeCloseButton_
---@type Button
local unlockMapButton_
---@type Button
local unlockBuildingButton_
---@type Widget
local ascensionPanel_
---@type Button
local ascensionOpenButton_
---@type Label
local ascensionRewardLabel_
---@type Label
local ascensionProgressLabel_
---@type Button
local ascensionConfirmButton_
---@type Label
local ascensionToastLabel_
---@type Widget
local offlineRewardPanel_
---@type Label
local offlineRewardLabel_
---@type Button
local claimOfflineButton_
---@type Widget
local canvasInputArea_

---@class RevenueGearData
---@field id integer
---@field gearType string
---@field level integer
---@field xNorm number
---@field yNorm number
---@field x number
---@field y number
---@field radius number
---@field teeth integer
---@field angle number
---@field connected boolean
---@field meshed boolean
---@field jammed boolean
---@field spinDirection integer
---@field rpm number
---@field rpmRatio number
---@field torque number
---@field incomePerSecond number
---@field transmissionDepth integer
---@field parentIndex integer|nil
---@field inputRing string|nil
---@field load number
---@field layerSpeedFactor number
---@field speedCapped boolean
---@field overloaded boolean

---@class GearWorkshopGameData
---@field coins integer
---@field gearEssence integer
---@field runCoinsEarned integer
---@field lifetimeCoinsEarned integer
---@field ascensionCount integer
---@field metaRevision integer
---@field unlockedSubMaps table<string, boolean>
---@field unlockedBuildings table<string, boolean>
---@field growthWindowStartTimestamp integer
---@field growthWindowElapsedSeconds number
---@field growthWindowStartIncome number
---@field ascensionRecommendationShown boolean
---@field mommaFactoryStock integer
---@field mommaFactoryProgressSeconds number
---@field mommaFactoryLastTimestamp integer
---@field clickLevel integer
---@field mainTorqueLevel integer
---@field mainCircleIncomeLevel integer
---@field nextGearId integer
---@field revenueGears RevenueGearData[]
---@field autoDriveUnlocked boolean
---@field autoDriveLevel integer
---@field globalIncomeLevel integer
---@field decayReductionLevel integer
---@field offlineIncomeLevel integer
---@field lastActiveTimestamp integer
---@field savedIncomePerSecond number
---@field pendingOfflineCoins integer
---@field pendingOfflineSeconds integer
---@type GearWorkshopGameData
local gameData_ = {
    coins = 0,
    gearEssence = 0,
    runCoinsEarned = 0,
    lifetimeCoinsEarned = 0,
    ascensionCount = 0,
    metaRevision = 0,
    unlockedSubMaps = { workshop = true },
    unlockedBuildings = {},
    growthWindowStartTimestamp = 0,
    growthWindowElapsedSeconds = 0,
    growthWindowStartIncome = 0,
    ascensionRecommendationShown = false,
    mommaFactoryStock = 0,
    mommaFactoryProgressSeconds = 0,
    mommaFactoryLastTimestamp = 0,
    clickLevel = 1,
    mainTorqueLevel = 0,
    mainCircleIncomeLevel = 0,
    nextGearId = 1,
    revenueGears = {},
    autoDriveUnlocked = false,
    autoDriveLevel = 0,
    globalIncomeLevel = 0,
    decayReductionLevel = 0,
    offlineIncomeLevel = 0,
    lastActiveTimestamp = 0,
    savedIncomePerSecond = 0,
    pendingOfflineCoins = 0,
    pendingOfflineSeconds = 0,
}

---@type number
local physicalWidth_ = 1
---@type number
local physicalHeight_ = 1
---@type number
local dpr_ = 1
---@type number
local logicalWidth_ = 1
---@type number
local logicalHeight_ = 1
---@type number
local mainGearX_ = 0
---@type number
local mainGearY_ = 0
---@type number
local mainGearRadius_ = 92
---@type number
local revenueGearRadius_ = 44
---@type number
local meshTolerance_ = 7
---@type number
local snapTolerance_ = 22
---@type number
local canvasMinY_ = 150
---@type number
local canvasMaxY_ = 700
---@type number
local mainGearAngle_ = 0
---@type number
local warningPhase_ = 0
---@type number
local manualRotationRemaining_ = 0
---@type number
local mainGearPulse_ = 0
---@type number
local incomeAccumulator_ = 0
local connectedGearCount_ = 0
---@type number
local totalIncomePerSecond_ = 0
---@class GearNetworkState
---@field jammed boolean
---@field overloaded boolean
---@field conflictPairs table[]
---@field totalIncomePerSecond number
---@field sourcePowered boolean
---@field sourceRPM number
---@field sourceTorque number
---@field totalLoad number
---@field fixedLoad number
---@field remainingTorque number
---@field loadByLayer table<integer, number>
---@field speedFactorByLayer table<integer, number>
---@field speedCapped boolean
---@field meshedCount integer
---@type GearNetworkState
local networkState_ = {
    jammed = false,
    overloaded = false,
    conflictPairs = {},
    totalIncomePerSecond = 0,
    sourcePowered = false,
    sourceRPM = 0,
    sourceTorque = GearDefinitions.Main.baseTorque,
    totalLoad = 0,
    fixedLoad = 0,
    remainingTorque = GearDefinitions.Main.baseTorque,
    loadByLayer = {},
    speedFactorByLayer = {},
    speedCapped = false,
    meshedCount = 0,
}
local connections_ = {}
local saveDirty_ = false
---@type number
local saveTimer_ = 0
local cloudMetaLoaded_ = false
local cloudMetaWritePending_ = false
---@type number
local ascensionToastTimer_ = 0
---@type number
local recommendationCheckTimer_ = 1.0
---@type number
local factoryUpdateTimer_ = 1.0

---@type integer|nil
local activePointerId_ = nil
---@type string|nil
local activePointerType_ = nil
---@type integer|nil
local draggedGearIndex_ = nil
---@type integer|nil
local selectedGearIndex_ = nil
---@type integer|nil
local placementGearIndex_ = nil
local dragPlacementValid_ = true
local dragSnapValid_ = false
local dragSnapRing_ = nil
local dragAnchorRing_ = nil
---@type integer|nil
local axleAssemblyTargetIndex_ = nil
---@class ShopDragState
---@field gearType string|nil
---@field pointerId integer|nil
---@field pointerType string|nil
---@field activated boolean
---@field overCanvas boolean
---@field placementValid boolean
---@field startX number
---@field startY number
---@field screenX number
---@field screenY number
---@field worldX number
---@field worldY number
---@type ShopDragState
local shopDrag_ = {
    gearType = nil,
    pointerId = nil,
    pointerType = nil,
    activated = false,
    overCanvas = false,
    placementValid = false,
    startX = 0,
    startY = 0,
    screenX = 0,
    screenY = 0,
    worldX = 0,
    worldY = 0,
}
local dragActivated_ = false
local pointerStartedOnMainGear_ = false
local pointerMoved_ = false
---@type number
local pointerStartX_ = 0
---@type number
local pointerStartY_ = 0
---@type number
local dragOffsetX_ = 0
---@type number
local dragOffsetY_ = 0
---@type number
local dragOriginalX_ = 0
---@type number
local dragOriginalY_ = 0
---@type number
local pointerLastX_ = 0
---@type number
local pointerLastY_ = 0
local canvasPanning_ = false
---@type number
local canvasScale_ = 1
---@type number
local canvasOffsetX_ = 0
---@type number
local canvasOffsetY_ = 0
---@class CanvasTouchPoint
---@field x number
---@field y number
---@type table<integer, CanvasTouchPoint>
local activeTouches_ = {}
local pinchActive_ = false
---@type number
local pinchStartDistance_ = 1
---@type number
local pinchStartScale_ = 1
---@type number
local pinchAnchorWorldX_ = 0
---@type number
local pinchAnchorWorldY_ = 0
---@type fun(pointerId: integer, pointerType: string|nil)|nil
local CancelCanvasPointer
---@type fun()|nil
local RefreshUI
---@type fun(reason: string, logChange: boolean)|nil
local RebuildGearNetwork

local function GetClickValue()
    return math.min(
        GearDefinitions.Main.manualClickMax,
        math.max(
            1,
            math.floor(
                GearDefinitions.GetMainClickIncome(
                    gameData_.clickLevel - 1
                )
                    * GearDefinitions.GetGlobalIncomeMultiplier(
                        gameData_.globalIncomeLevel
                    )
            )
        )
    )
end

local function GetUpgradeCost()
    return GearDefinitions.GetMainUpgradeCost(
        "manualClick",
        gameData_.clickLevel - 1
    )
end

local function CreditCoins(amount)
    local earned = math.max(0, math.floor(amount))
    if earned <= 0 then
        return 0
    end
    gameData_.coins = gameData_.coins + earned
    gameData_.runCoinsEarned = gameData_.runCoinsEarned + earned
    gameData_.lifetimeCoinsEarned =
        gameData_.lifetimeCoinsEarned + earned
    gameData_.metaRevision = gameData_.metaRevision + 1
    return earned
end

local function GetMainTorque()
    return GearDefinitions.GetMainTorque(gameData_.mainTorqueLevel)
end

local function GetMainCircleIncome()
    return GearDefinitions.GetMainCircleIncome(
        gameData_.mainCircleIncomeLevel
    )
end

local function GetMainRPM()
    return math.min(
        GearDefinitions.Main.maxRPM,
        GearDefinitions.Main.baseRPM
    )
end

local function IsMainSpeedCapped()
    return gameData_.autoDriveUnlocked
        and GetMainRPM() >= GearDefinitions.Main.maxRPM
end

local function FormatNumber(value)
    if value >= 1000000000 then
        return string.format("%.2fB", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.2fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.2fK", value / 1000)
    end

    return tostring(value)
end

local function DistanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

local function UIToLogical(uiX, uiY)
    local scale = UI.GetScale() / dpr_
    return uiX * scale, uiY * scale
end

local function PhysicalToLogical(physicalX, physicalY)
    return physicalX / dpr_, physicalY / dpr_
end

local function ScreenToWorld(screenX, screenY)
    return (screenX - canvasOffsetX_) / canvasScale_,
        (screenY - canvasOffsetY_) / canvasScale_
end

local function GetTouchPair()
    ---@type integer|nil
    local firstId = nil
    ---@type integer|nil
    local secondId = nil
    for touchId in pairs(activeTouches_) do
        if firstId == nil then
            firstId = touchId
        else
            secondId = touchId
            break
        end
    end
    return firstId, secondId
end

local function BeginPinch()
    local firstId, secondId = GetTouchPair()
    if firstId == nil or secondId == nil then
        return
    end

    ---@type CanvasTouchPoint
    local first = activeTouches_[firstId]
    ---@type CanvasTouchPoint
    local second = activeTouches_[secondId]
    local centerX = (first.x + second.x) * 0.5
    local centerY = (first.y + second.y) * 0.5
    pinchStartDistance_ = math.max(
        1,
        math.sqrt(DistanceSquared(first.x, first.y, second.x, second.y))
    )
    pinchStartScale_ = canvasScale_
    pinchAnchorWorldX_, pinchAnchorWorldY_ = ScreenToWorld(centerX, centerY)
    pinchActive_ = true

    if activePointerId_ ~= nil and CancelCanvasPointer then
        CancelCanvasPointer(activePointerId_, activePointerType_)
    end
    print(string.format("[Canvas] 开始双指缩放 scale=%.2f", canvasScale_))
end

local function UpdatePinch()
    local firstId, secondId = GetTouchPair()
    if not pinchActive_ or firstId == nil or secondId == nil then
        return
    end

    ---@type CanvasTouchPoint
    local first = activeTouches_[firstId]
    ---@type CanvasTouchPoint
    local second = activeTouches_[secondId]
    local centerX = (first.x + second.x) * 0.5
    local centerY = (first.y + second.y) * 0.5
    local distance = math.sqrt(DistanceSquared(
        first.x,
        first.y,
        second.x,
        second.y
    ))
    canvasScale_ = math.max(
        0.65,
        math.min(2.0, pinchStartScale_ * distance / pinchStartDistance_)
    )
    canvasOffsetX_ = centerX - pinchAnchorWorldX_ * canvasScale_
    canvasOffsetY_ = centerY - pinchAnchorWorldY_ * canvasScale_
end

local function EndPinchIfNeeded()
    local firstId, secondId = GetTouchPair()
    if firstId == nil or secondId == nil then
        if pinchActive_ then
            print(string.format("[Canvas] 结束双指缩放 scale=%.2f", canvasScale_))
        end
        pinchActive_ = false
    end
end

local function UpdateGearNormalizedPosition(gear)
    gear.xNorm = gear.x / logicalWidth_
    gear.yNorm = gear.y / logicalHeight_
end

local function MarkSaveDirty(delay)
    local requestedDelay = delay or CONFIG.AutoSaveDelay
    if not saveDirty_ then
        saveDirty_ = true
        saveTimer_ = requestedDelay
    else
        saveTimer_ = math.min(saveTimer_, requestedDelay)
    end
end

---@type fun()
local SaveMetaToCloud

SaveMetaToCloud = function()
    if clientCloud == nil or cloudMetaWritePending_ then
        return
    end

    local snapshot = MetaProgression.CreateCloudSnapshot(gameData_)
    local submittedRevision = snapshot.revision
    cloudMetaWritePending_ = true
    clientCloud:Set(MetaProgression.CloudKey, snapshot, {
        ok = function()
            cloudMetaWritePending_ = false
            print(string.format(
                "[MetaCloud] 永久进度同步成功 revision=%d essence=%d",
                submittedRevision,
                snapshot.gearEssence
            ))
            if gameData_.metaRevision > submittedRevision then
                SaveMetaToCloud()
            end
        end,
        error = function(code, reason)
            cloudMetaWritePending_ = false
            print(string.format(
                "[MetaCloud] 永久进度同步失败 code=%s reason=%s",
                tostring(code),
                tostring(reason)
            ))
        end,
        timeout = function()
            cloudMetaWritePending_ = false
            print("[MetaCloud] 永久进度同步超时，保留本地双槽数据")
        end,
    })
end

local function MarkMetaChanged()
    gameData_.metaRevision = gameData_.metaRevision + 1
    MarkSaveDirty(0)
    if cloudMetaLoaded_ then
        SaveMetaToCloud()
    end
end

local function LoadMetaFromCloud()
    if clientCloud == nil then
        cloudMetaLoaded_ = true
        print("[MetaCloud] 当前环境无云变量，使用本地永久进度")
        return
    end

    clientCloud:Get(MetaProgression.CloudKey, {
        ok = function(values)
            local cloudValue = type(values) == "table"
                and values[MetaProgression.CloudKey]
                or nil
            local cloudSnapshot = MetaProgression.NormalizeCloudSnapshot(
                cloudValue
            )
            if MetaProgression.ShouldUseCloud(gameData_, cloudSnapshot) then
                MetaProgression.ApplyCloudSnapshot(gameData_, cloudSnapshot)
                MarkSaveDirty(0)
                if RebuildGearNetwork then
                    RebuildGearNetwork("云端永久进度恢复", true)
                end
                if RefreshUI then
                    RefreshUI()
                end
                print(string.format(
                    "[MetaCloud] 已恢复云端永久进度 revision=%d essence=%d",
                    gameData_.metaRevision,
                    gameData_.gearEssence
                ))
            elseif cloudSnapshot == nil
                and (gameData_.gearEssence > 0
                    or gameData_.ascensionCount > 0
                    or gameData_.globalIncomeLevel > 0
                    or gameData_.decayReductionLevel > 0
                    or gameData_.offlineIncomeLevel > 0) then
                gameData_.metaRevision = math.max(
                    1,
                    gameData_.metaRevision
                )
                MarkSaveDirty(0)
                print("[MetaCloud] 发现旧版本地永久进度，准备首次迁移")
            elseif gameData_.metaRevision > 0 then
                print("[MetaCloud] 本地永久进度较新，准备回写云端")
            end
            cloudMetaLoaded_ = true
            if gameData_.metaRevision > 0
                and (cloudSnapshot == nil
                    or gameData_.metaRevision > cloudSnapshot.revision) then
                SaveMetaToCloud()
            end
        end,
        error = function(code, reason)
            cloudMetaLoaded_ = true
            print(string.format(
                "[MetaCloud] 读取失败 code=%s reason=%s，继续使用本地永久进度",
                tostring(code),
                tostring(reason)
            ))
        end,
        timeout = function()
            cloudMetaLoaded_ = true
            print("[MetaCloud] 读取超时，继续使用本地永久进度")
        end,
    })
end

local function SaveNow(reason)
    if not saveDirty_ then
        return
    end

    gameData_.lastActiveTimestamp = os.time()
    gameData_.savedIncomePerSecond = totalIncomePerSecond_
    gameData_.metaRevision = gameData_.metaRevision + 1

    print("[Game] 执行自动存档，原因: " .. reason)
    if SaveSystem.Save(gameData_) then
        saveDirty_ = false
        saveTimer_ = 0
        if cloudMetaLoaded_ then
            SaveMetaToCloud()
        end
    end
end

local function GetRevenueGear(index)
    ---@type RevenueGearData
    local gear = assert(gameData_.revenueGears[index])
    return gear
end

local function FormatStat(value)
    return string.format("%.2f", value)
end

local function FormatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = math.floor(seconds % 60)

    if hours > 0 then
        return string.format("%d小时%d分", hours, minutes)
    elseif minutes > 0 then
        return string.format("%d分%d秒", minutes, remainingSeconds)
    end

    return string.format("%d秒", remainingSeconds)
end

local function GetGlobalIncomeMultiplier()
    return GearDefinitions.GetGlobalIncomeMultiplier(
        gameData_.globalIncomeLevel
    )
end

local function GetTransmissionDecay()
    return GearDefinitions.GetTransmissionDecay(
        gameData_.decayReductionLevel
    )
end

local function GetOfflineMultiplier()
    return GearDefinitions.GetOfflineMultiplier(
        gameData_.offlineIncomeLevel
    )
end

local function RefreshSelectedGearUI()
    if selectedGearIndex_ == nil then
        gearDetailsPanel_:SetVisible(false)
        return
    end

    local gear = gameData_.revenueGears[selectedGearIndex_]
    if not gear then
        selectedGearIndex_ = nil
        gearDetailsPanel_:SetVisible(false)
        return
    end

    local definition = GearDefinitions.Get(gear.gearType)
    local status = "未连接动力"
    if gear.jammed then
        status = "传动闭环冲突，齿轮已卡死"
    elseif gear.overloaded then
        status = "总负载超过总扭矩，齿轮已锁死"
    elseif gear.connected then
        local inputRingName = gear.inputRing == "inner"
            and "内层小齿圈"
            or "外层齿圈"
        status = string.format(
            "动力已连接 · 第 %d 级传动 · 输入：%s",
            gear.transmissionDepth,
            inputRingName
        )
    elseif gear.meshed then
        status = string.format(
            "已咬合 · 第 %d 级传动 · 等待自动驱动解锁",
            gear.transmissionDepth
        )
    elseif not gameData_.autoDriveUnlocked then
        status = "未咬合 · 拖至齿圈边缘自动吸附"
    end

    local rings = GearDefinitions.GetRings(gear.gearType)
    local teethText = string.format("齿数  %d", rings.outer.teeth)
    if rings.inner then
        teethText = string.format(
            "外层齿数  %d\n内层齿数  %d",
            rings.outer.teeth,
            rings.inner.teeth
        )
    end

    local layerLoad = networkState_.loadByLayer[
        gear.transmissionDepth
    ] or 0
    local layerSpeedFactor = networkState_.speedFactorByLayer[
        gear.transmissionDepth
    ] or gear.layerSpeedFactor
    local upgradeCost = GearDefinitions.GetUpgradeCost(gear.gearType, gear.level)
    gearDetailsTitleLabel_:SetText(string.format("%s  #%d", definition.name, gear.id))
    gearDetailsStatusLabel_:SetText(status)
    gearDetailsStatsLabel_:SetText(string.format(
        "%s\n层级  %d · 齿轮负载  %s\n层负载  %s · 压速系数 x%s\n整体轴转速  %s RPM%s\n轴上传入扭矩  %s\n每秒收益  %s 金币",
        teethText,
        gear.transmissionDepth,
        FormatStat(gear.load),
        FormatStat(layerLoad),
        FormatStat(layerSpeedFactor),
        FormatStat(gear.rpm),
        gear.speedCapped and " · 触顶锁速" or "",
        FormatStat(gear.torque),
        FormatStat(gear.incomePerSecond)
    ))
    local specialtyText = ""
    if gear.gearType == "momma" then
        specialtyText = string.format(
            "\n母齿轮专属：固定变速 x11.25 · 极低负载 %.2f\n高扭矩承载 %.0f · 基础收益 %.0f",
            definition.baseLoad,
            definition.baseTorque,
            definition.baseIncome
        )
    elseif gear.gearType == "large_compound" then
        specialtyText = string.format(
            "\n同轴结构：大型外圈 %d 齿 + 小型内圈 %d 齿\n整根轴共享 RPM · 内外齿圈均可继续啮合",
            rings.outer.teeth,
            rings.inner.teeth
        )
    elseif gear.gearType == "large" then
        specialtyText = "\n装配提示：将小型齿轮拖到轴心，可转换为大型同轴复合齿轮"
    end
    gearDetailsUpgradeLabel_:SetText(string.format(
        "Lv.%d · 转速倍率 x%s · 承载容量 %s · 固定倍率 x%s · 收益 x%s%s",
        gear.level,
        FormatStat(GearDefinitions.GetSpeedMultiplier(gear.level)),
        FormatStat(GearDefinitions.GetTorqueCapacity(gear.gearType, gear.level)),
        FormatStat(GearDefinitions.GetFixedSpeedMultiplier(
            gear.gearType,
            gear.transmissionDepth
        )),
        FormatStat(GearDefinitions.GetIncomeMultiplier(gear.level)),
        specialtyText
    ))
    gearDetailsEssenceLabel_:SetText(string.format(
        "永久精华  %s · 已飞升 %d 次 · 全收益 x%s",
        FormatNumber(gameData_.gearEssence),
        gameData_.ascensionCount,
        FormatStat(GetGlobalIncomeMultiplier())
    ))
    gearUpgradeButton_:SetText("升级此齿轮  " .. FormatNumber(upgradeCost) .. " 金币")
    gearUpgradeButton_:SetDisabled(gameData_.coins < upgradeCost)
    gearDetailsPanel_:SetVisible(true)
end

local function RefreshRevenueUI()
    revenueLabel_:SetText("实时收益  $" .. FormatStat(totalIncomePerSecond_) .. "/s")

    local powerState = "待解锁自动运转"
    if networkState_.jammed then
        powerState = "传动冲突 · 全线锁死"
    elseif networkState_.overloaded then
        powerState = "负载过高 · 全线锁死"
    elseif gameData_.autoDriveUnlocked then
        powerState = string.format(
            "主轴 %.2f RPM · %s",
            networkState_.sourceRPM,
            IsMainSpeedCapped() and "触顶锁速" or "运行正常"
        )
    end

    powerStatusLabel_:SetText(string.format(
        "%s\n当前负载 / 总扭矩  %.2f / %.2f · 基建固定 %.2f",
        powerState,
        networkState_.totalLoad,
        networkState_.sourceTorque,
        networkState_.fixedLoad
    ))
    local loadRatio = networkState_.totalLoad
        / math.max(1, networkState_.sourceTorque)
    local clampedLoadRatio = math.min(1, math.max(0, loadRatio))
    loadProgressBar_:SetValue(clampedLoadRatio)
    loadGaugeLabel_:SetText(string.format(
        "负载占用  %.0f%%",
        loadRatio * 100
    ))
    if networkState_.overloaded then
        loadProgressBar_:SetStyle({ fillColor = { 255, 76, 70, 255 } })
        loadGaugeLabel_:SetStyle({ fontColor = { 255, 91, 82, 255 } })
    elseif loadRatio >= 0.75 then
        loadProgressBar_:SetStyle({ fillColor = { 255, 188, 61, 255 } })
        loadGaugeLabel_:SetStyle({ fontColor = { 255, 196, 79, 255 } })
    else
        loadProgressBar_:SetStyle({ fillColor = { 84, 215, 153, 255 } })
        loadGaugeLabel_:SetStyle({ fontColor = { 124, 207, 231, 245 } })
    end
    shopInfoLabel_:SetText(string.format(
        "已购买 %d · 已咬合 %d · 已驱动 %d · 远端负载回传 %.0f%%/层",
        #gameData_.revenueGears,
        networkState_.meshedCount,
        connectedGearCount_,
        GearDefinitions.RemoteBranchLoadFactor * 100
    ))
end

local function RefreshGlobalUpgradeUI()
    local incomeCost = GearDefinitions.GetGlobalUpgradeCost(
        "income",
        gameData_.globalIncomeLevel
    )
    local decayCost = GearDefinitions.GetGlobalUpgradeCost(
        "decay",
        gameData_.decayReductionLevel
    )
    local offlineCost = GearDefinitions.GetGlobalUpgradeCost(
        "offline",
        gameData_.offlineIncomeLevel
    )

    globalUpgradeSummaryLabel_:SetText(string.format(
        "齿轮精华 %s · 已飞升 %d 次\n永久全收益 x%s\n传动衰减 %.1f%%/级 · 离线收益 x%s",
        FormatNumber(gameData_.gearEssence),
        gameData_.ascensionCount,
        FormatStat(GetGlobalIncomeMultiplier()),
        GetTransmissionDecay() * 100,
        FormatStat(GetOfflineMultiplier())
    ))
    globalIncomeUpgradeButton_:SetText(string.format(
        "永恒增产 Lv.%d  %s精华",
        gameData_.globalIncomeLevel,
        FormatNumber(incomeCost)
    ))
    decayUpgradeButton_:SetText(string.format(
        "永恒润滑 Lv.%d  %s精华",
        gameData_.decayReductionLevel,
        FormatNumber(decayCost)
    ))
    offlineUpgradeButton_:SetText(string.format(
        "时流储能 Lv.%d  %s精华",
        gameData_.offlineIncomeLevel,
        FormatNumber(offlineCost)
    ))
    globalIncomeUpgradeButton_:SetDisabled(
        gameData_.gearEssence < incomeCost
    )
    decayUpgradeButton_:SetDisabled(
        gameData_.gearEssence < decayCost
            or GetTransmissionDecay() <= 0.01001
    )
    if GetTransmissionDecay() <= 0.01001 then
        decayUpgradeButton_:SetText(string.format(
            "永恒润滑 Lv.%d  已满级",
            gameData_.decayReductionLevel
        ))
    end
    offlineUpgradeButton_:SetDisabled(
        gameData_.gearEssence < offlineCost
    )

    local mapDefinition = GearDefinitions.GetMetaUnlock(
        "subMaps",
        "scrapyard"
    )
    local mapUnlocked = gameData_.unlockedSubMaps.scrapyard == true
    unlockMapButton_:SetText(mapUnlocked
        and (mapDefinition.name .. "  已解锁")
        or string.format(
            "解锁%s  %d精华",
            mapDefinition.name,
            mapDefinition.cost
        ))
    unlockMapButton_:SetDisabled(
        mapUnlocked or gameData_.gearEssence < mapDefinition.cost
    )

    local buildingDefinition = GearDefinitions.GetMetaUnlock(
        "buildings",
        "precisionFoundry"
    )
    local buildingUnlocked =
        gameData_.unlockedBuildings.precisionFoundry == true
    unlockBuildingButton_:SetText(buildingUnlocked
        and (buildingDefinition.name .. "  已解锁")
        or string.format(
            "解锁%s  %d精华",
            buildingDefinition.name,
            buildingDefinition.cost
        ))
    unlockBuildingButton_:SetDisabled(
        buildingUnlocked
            or gameData_.gearEssence < buildingDefinition.cost
    )
end

local function RefreshOfflineRewardUI()
    local hasReward = gameData_.pendingOfflineCoins > 0
    if hasReward then
        offlineRewardLabel_:SetText(string.format(
            "离线 %s\n累计 %s 金币",
            FormatDuration(gameData_.pendingOfflineSeconds),
            FormatNumber(gameData_.pendingOfflineCoins)
        ))
        claimOfflineButton_:SetText(
            "领取 " .. FormatNumber(gameData_.pendingOfflineCoins) .. " 金币"
        )
    end
    offlineRewardPanel_:SetVisible(hasReward)
end

RefreshUI = function()
    local clickValue = GetClickValue()
    local upgradeCost = GetUpgradeCost()
    local small = GearDefinitions.Get("small")
    local medium = GearDefinitions.Get("medium")
    local large = GearDefinitions.Get("large")
    local momma = GearDefinitions.Get("momma")

    coinLabel_:SetText("金币  " .. FormatNumber(gameData_.coins))
    local ascensionReward = GearDefinitions.GetAscensionReward(
        gameData_.runCoinsEarned
    )
    essenceLabel_:SetText(string.format(
        "齿轮精华  %s · 飞升 +%s",
        FormatNumber(gameData_.gearEssence),
        FormatNumber(ascensionReward)
    ))
    clickValueLabel_:SetText("手动点击  +" .. FormatNumber(clickValue))
    levelLabel_:SetText(string.format(
        "主齿轮：扭矩 Lv.%d · 单圈 Lv.%d · 点击 Lv.%d",
        gameData_.mainTorqueLevel,
        gameData_.mainCircleIncomeLevel,
        gameData_.clickLevel
    ))
    upgradeButton_:SetText("升级手动点击  " .. FormatNumber(upgradeCost) .. " 金币")
    upgradeButton_:SetDisabled(
        gameData_.coins < upgradeCost
            or GetClickValue() >= GearDefinitions.Main.manualClickMax
    )

    local torqueCost = GearDefinitions.GetMainUpgradeCost(
        "torque",
        gameData_.mainTorqueLevel
    )
    mainTorqueUpgradeButton_:SetText(string.format(
        "扭矩上限 Lv.%d  %s金币",
        gameData_.mainTorqueLevel,
        FormatNumber(torqueCost)
    ))
    mainTorqueUpgradeButton_:SetDisabled(
        gameData_.coins < GearDefinitions.TorqueUpgradeUnlockCoins
            or gameData_.coins < torqueCost
    )

    local circleCost = GearDefinitions.GetMainUpgradeCost(
        "circleIncome",
        gameData_.mainCircleIncomeLevel
    )
    mainCircleIncomeUpgradeButton_:SetText(string.format(
        "单圈收益 Lv.%d  %s金币",
        gameData_.mainCircleIncomeLevel,
        FormatNumber(circleCost)
    ))
    mainCircleIncomeUpgradeButton_:SetDisabled(
        gameData_.coins < circleCost
    )

    buySmallGearPriceLabel_:SetText(string.format("%d 金币", small.purchaseCost))
    buySmallGearButton_:SetClickable(gameData_.coins >= small.purchaseCost)
    buySmallGearButton_:SetOpacity(gameData_.coins >= small.purchaseCost and 1 or 0.48)
    buyMediumGearPriceLabel_:SetText(string.format("%d 金币", medium.purchaseCost))
    buyMediumGearButton_:SetClickable(gameData_.coins >= medium.purchaseCost)
    buyMediumGearButton_:SetOpacity(gameData_.coins >= medium.purchaseCost and 1 or 0.48)
    buyLargeGearPriceLabel_:SetText(string.format("%d 金币", large.purchaseCost))
    buyLargeGearButton_:SetClickable(gameData_.coins >= large.purchaseCost)
    buyLargeGearButton_:SetOpacity(gameData_.coins >= large.purchaseCost and 1 or 0.48)

    local compound = GearDefinitions.Get("compound")
    buyCompoundGearPriceLabel_:SetText(string.format(
        "%d 金币",
        compound.purchaseCost
    ))
    buyCompoundGearButton_:SetClickable(
        gameData_.coins >= compound.purchaseCost
    )
    buyCompoundGearButton_:SetOpacity(
        gameData_.coins >= compound.purchaseCost and 1 or 0.48
    )
    buyMommaGearPriceLabel_:SetText(string.format(
        "%d 金币",
        momma.purchaseCost
    ))
    buyMommaGearButton_:SetClickable(
        gameData_.coins >= momma.purchaseCost
    )
    buyMommaGearButton_:SetOpacity(
        gameData_.coins >= momma.purchaseCost and 1 or 0.48
    )

    local factory = GearDefinitions.MommaFactory
    local factoryUnlocked =
        gameData_.unlockedBuildings.precisionFoundry == true
    local cycleSeconds = GearDefinitions.GetMommaFactoryProductionSeconds(
        gameData_.ascensionCount
    )
    local remainingSeconds = math.max(
        0,
        cycleSeconds - gameData_.mommaFactoryProgressSeconds
    )
    if factoryUnlocked then
        local speedBonus = math.min(
            factory.maxAscensionSpeedBonus,
            gameData_.ascensionCount
                * factory.ascensionSpeedBonusPerCount
        )
        factoryStatusLabel_:SetText(string.format(
            "巨型工厂 · 库存 %d/%d\n下一枚 %s · 飞升提速 %.0f%% · 固定负载 %.0f",
            gameData_.mommaFactoryStock,
            factory.maxStock,
            gameData_.mommaFactoryStock >= factory.maxStock
                and "库存已满"
                or FormatDuration(remainingSeconds),
            speedBonus * 100,
            factory.fixedLoad
        ))
    else
        factoryStatusLabel_:SetText(string.format(
            "巨型工厂 · 未解锁\n消耗精华解锁 · 固定负载 %.0f",
            factory.fixedLoad
        ))
    end
    factoryClaimButton_:SetDisabled(
        not factoryUnlocked or gameData_.mommaFactoryStock <= 0
    )
    factoryClaimButton_:SetText(
        gameData_.mommaFactoryStock > 0
            and "领取母齿轮"
            or "等待生产"
    )

    if gameData_.autoDriveUnlocked then
        autoDriveButton_:SetText("自动运转  已解锁 · 0.03 圈/秒")
        autoDriveButton_:SetDisabled(false)
        autoDriveButton_:SetOpacity(1)
    else
        autoDriveButton_:SetText(string.format(
            "自动运转：扭矩 Lv.%d 解锁 · 点击查看条件",
            GearDefinitions.Main.autoUnlockTorqueLevel
        ))
        autoDriveButton_:SetDisabled(false)
        autoDriveButton_:SetOpacity(0.72)
    end

    RefreshRevenueUI()
    RefreshSelectedGearUI()
    RefreshGlobalUpgradeUI()
    local currentAscensionReward = GearDefinitions.GetAscensionReward(
        gameData_.runCoinsEarned
    )
    ascensionOpenButton_:SetText(string.format(
        "飞升重构  +%s精华",
        FormatNumber(currentAscensionReward)
    ))
    ascensionRewardLabel_:SetText(string.format(
        "本次预计获得 %s 齿轮精华",
        FormatNumber(currentAscensionReward)
    ))
    ascensionProgressLabel_:SetText(string.format(
        "本局累计 %s 金币 · 每 %s 金币折算 1 精华\n历史累计 %s 金币 · 已完成 %d 次飞升",
        FormatNumber(gameData_.runCoinsEarned),
        FormatNumber(GearDefinitions.Ascension.essenceCoinRatio),
        FormatNumber(gameData_.lifetimeCoinsEarned),
        gameData_.ascensionCount
    ))
    ascensionConfirmButton_:SetDisabled(currentAscensionReward <= 0)
    RefreshOfflineRewardUI()
end

RebuildGearNetwork = function(reason, logChange)
    local previousConnectedCount = connectedGearCount_
    local previousIncome = totalIncomePerSecond_
    ---@type GearNetworkState
    local rebuiltState
    connectedGearCount_, connections_, rebuiltState = GearSystem.Rebuild(
        gameData_.revenueGears,
        mainGearX_,
        mainGearY_,
        mainGearRadius_,
        meshTolerance_,
        GetGlobalIncomeMultiplier(),
        GetTransmissionDecay(),
        gameData_.autoDriveUnlocked,
        GetMainRPM(),
        GetMainTorque(),
        GetMainCircleIncome(),
        {},
        gameData_.unlockedBuildings.precisionFoundry == true
            and GearDefinitions.MommaFactory.fixedLoad
            or 0
    )
    networkState_ = rebuiltState
    totalIncomePerSecond_ = networkState_.totalIncomePerSecond

    if previousConnectedCount ~= connectedGearCount_
        or math.abs(previousIncome - totalIncomePerSecond_) > 0.0001 then
        RefreshRevenueUI()
    end
    RefreshSelectedGearUI()

    if logChange then
        print(string.format(
            "[GearNetwork] %s: connected=%d, edges=%d, income=%.2f/s, jammed=%s",
            reason,
            connectedGearCount_,
            #connections_,
            totalIncomePerSecond_,
            tostring(networkState_.jammed)
        ))
    end
end

local function RefreshLayout()
    physicalWidth_ = graphics:GetWidth()
    physicalHeight_ = graphics:GetHeight()
    dpr_ = math.max(graphics:GetDPR(), 1)
    logicalWidth_ = physicalWidth_ / dpr_
    logicalHeight_ = physicalHeight_ / dpr_

    mainGearX_ = logicalWidth_ * 0.5
    mainGearY_ = logicalHeight_ * 0.47
    mainGearRadius_ = math.min(
        logicalWidth_ * 0.115,
        logicalHeight_ * 0.055,
        62
    )
    revenueGearRadius_ = mainGearRadius_
    meshTolerance_ = math.max(4, mainGearRadius_ * 0.07)
    snapTolerance_ = math.max(28, mainGearRadius_ * 0.45)
    canvasMinY_ = 0
    canvasMaxY_ = logicalHeight_

    for _, gear in ipairs(gameData_.revenueGears) do
        local definition = GearDefinitions.Get(gear.gearType)
        gear.teeth = definition.teeth
        gear.radius = revenueGearRadius_ * definition.radiusScale
        gear.x = gear.xNorm * logicalWidth_
        gear.y = gear.yNorm * logicalHeight_
        gear.angle = gear.angle or 0
        gear.connected = false
        gear.meshed = false
        gear.jammed = false
        gear.spinDirection = 0
        gear.rpm = 0
        gear.rpmRatio = 0
        gear.torque = 0
        gear.incomePerSecond = 0
        gear.transmissionDepth = 0
        gear.parentIndex = nil
        UpdateGearNormalizedPosition(gear)
    end

    RebuildGearNetwork("屏幕布局更新", true)

    print(string.format(
        "[Layout] physical=%dx%d, dpr=%.2f, logical=%.1fx%.1f, mainRadius=%.1f, revenueRadius=%.1f",
        physicalWidth_,
        physicalHeight_,
        dpr_,
        logicalWidth_,
        logicalHeight_,
        mainGearRadius_,
        revenueGearRadius_
    ))
end

local function AddCoinsFromMainGear()
    local amount = CreditCoins(GetClickValue())
    manualRotationRemaining_ = manualRotationRemaining_ + math.pi * 2
    mainGearPulse_ = 1

    print(string.format(
        "[Game] 点击主齿轮: +%d 金币，当前金币=%d",
        amount,
        gameData_.coins
    ))

    RefreshUI()
    MarkSaveDirty()
end

local function ShowAutoDriveRequirement()
    local message
    if gameData_.autoDriveUnlocked then
        message = "自动运转已解锁。\n当前基础转速：0.03 圈/秒（1.8 RPM）。"
    else
        message = string.format(
            "主齿轮扭矩达到 Lv.%d 后自动解锁。\n当前扭矩等级：Lv.%d",
            GearDefinitions.Main.autoUnlockTorqueLevel,
            gameData_.mainTorqueLevel
        )
    end
    UI.Modal.Alert({
        title = "自动运转解锁条件",
        message = message,
        buttonText = "知道了",
    })
end

local function UnlockAutoDrive()
    if gameData_.autoDriveUnlocked then
        return
    end

    if not GearDefinitions.CanUnlockAutoDrive(
        gameData_.mainTorqueLevel
    ) then
        print(string.format(
            "[Drive] 扭矩未达标: 当前Lv.%d, 需要Lv.%d",
            gameData_.mainTorqueLevel,
            GearDefinitions.Main.autoUnlockTorqueLevel
        ))
        return
    end

    gameData_.autoDriveUnlocked = true
    gameData_.autoDriveLevel = 1
    manualRotationRemaining_ = 0
    RebuildGearNetwork("扭矩达标解锁自动运转", true)
    RefreshUI()
    MarkSaveDirty()
    SaveNow("解锁自动运转")
    print("[Drive] 主驱动齿轮扭矩达标，自动运转已解锁")
end

local function UpgradeMainTorque()
    if gameData_.coins < GearDefinitions.TorqueUpgradeUnlockCoins then
        return
    end

    local cost = GearDefinitions.GetMainUpgradeCost(
        "torque",
        gameData_.mainTorqueLevel
    )
    if gameData_.coins < cost then
        return
    end

    gameData_.coins = math.floor(gameData_.coins - cost)
    gameData_.mainTorqueLevel = gameData_.mainTorqueLevel + 1
    if GearDefinitions.CanUnlockAutoDrive(gameData_.mainTorqueLevel) then
        gameData_.autoDriveUnlocked = true
        gameData_.autoDriveLevel = 1
    end
    RebuildGearNetwork("主轴扭矩升级", true)
    RefreshUI()
    MarkSaveDirty()
    SaveNow("主轴扭矩升级")
end

local function UpgradeMainCircleIncome()
    local cost = GearDefinitions.GetMainUpgradeCost(
        "circleIncome",
        gameData_.mainCircleIncomeLevel
    )
    if gameData_.coins < cost then
        return
    end

    gameData_.coins = math.floor(gameData_.coins - cost)
    gameData_.mainCircleIncomeLevel =
        gameData_.mainCircleIncomeLevel + 1
    RebuildGearNetwork("主齿轮单圈收益升级", true)
    RefreshUI()
    MarkSaveDirty()
    SaveNow("主齿轮单圈收益升级")
end

local function UpgradeClickValue()
    local cost = GetUpgradeCost()
    if gameData_.coins < cost then
        print(string.format("[Game] 升级金币不足: 当前=%d, 需要=%d", gameData_.coins, cost))
        return
    end

    gameData_.coins = gameData_.coins - cost
    gameData_.clickLevel = gameData_.clickLevel + 1

    print(string.format(
        "[Game] 点击收益升级成功: level=%d, clickValue=%d, coins=%d",
        gameData_.clickLevel,
        GetClickValue(),
        gameData_.coins
    ))

    RefreshUI()
    MarkSaveDirty()
    SaveNow("升级完成")
end

local function FindPurchaseSpawnPosition(radius)
    local gearIndex = #gameData_.revenueGears
    local columns = 5
    local column = gearIndex % columns
    local row = math.floor(gearIndex / columns) % 2
    local spacing = mainGearRadius_ * 1.35
    local totalWidth = (columns - 1) * spacing
    local x = mainGearX_ - totalWidth * 0.5 + column * spacing
    local y = canvasMaxY_ - radius - 18 - row * spacing
    return x, y
end

local function CreateRevenueGearAt(gearType, source, spawnX, spawnY)
    local definition = GearDefinitions.Get(gearType)
    ---@type number
    local radius = revenueGearRadius_ * definition.radiusScale
    spawnX = spawnX or select(1, FindPurchaseSpawnPosition(radius))
    spawnY = spawnY or select(2, FindPurchaseSpawnPosition(radius))

    ---@type RevenueGearData
    local gear = {
        id = gameData_.nextGearId,
        gearType = definition.type,
        level = 1,
        xNorm = spawnX / logicalWidth_,
        yNorm = spawnY / logicalHeight_,
        x = spawnX,
        y = spawnY,
        radius = radius,
        teeth = definition.teeth,
        angle = 0,
        connected = false,
        meshed = false,
        jammed = false,
        spinDirection = 0,
        rpm = 0,
        rpmRatio = 0,
        torque = 0,
        incomePerSecond = 0,
        transmissionDepth = 0,
        parentIndex = nil,
        inputRing = nil,
        load = 0,
        layerSpeedFactor = 0,
        speedCapped = false,
        overloaded = false,
    }

    gameData_.nextGearId = gameData_.nextGearId + 1
    gameData_.revenueGears[#gameData_.revenueGears + 1] = gear
    local gearIndex = #gameData_.revenueGears
    selectedGearIndex_ = gearIndex
    placementGearIndex_ = gearIndex
    UpdateGearNormalizedPosition(gear)
    RebuildGearNetwork(source .. "创建齿轮", true)
    print(string.format(
        "[GearCreate] source=%s type=%s id=%d teeth=%d spawn=(%.1f, %.1f)",
        source,
        definition.type,
        gear.id,
        gear.teeth,
        gear.x,
        gear.y
    ))
    return gearIndex
end

local function ClearShopDragState()
    shopDrag_.gearType = nil
    shopDrag_.pointerId = nil
    shopDrag_.pointerType = nil
    shopDrag_.activated = false
    shopDrag_.overCanvas = false
    shopDrag_.placementValid = false
end

local function UpdateShopDragPreview(screenX, screenY, overCanvas)
    if shopDrag_.gearType == nil then
        return
    end

    shopDrag_.screenX = screenX
    shopDrag_.screenY = screenY
    shopDrag_.overCanvas = overCanvas == true
    local moved = DistanceSquared(
        screenX,
        screenY,
        shopDrag_.startX,
        shopDrag_.startY
    ) > CONFIG.DragThreshold ^ 2
    if moved then
        shopDrag_.activated = true
    end

    local worldX, worldY = ScreenToWorld(screenX, screenY)
    local definition = GearDefinitions.Get(shopDrag_.gearType)
    local radius = revenueGearRadius_ * definition.radiusScale
    local snappedX, snappedY = GearSystem.FindSnapPosition(
        worldX,
        worldY,
        radius,
        gameData_.revenueGears,
        -1,
        mainGearX_,
        mainGearY_,
        mainGearRadius_,
        snapTolerance_,
        shopDrag_.gearType
    )
    worldX = snappedX or worldX
    worldY = snappedY or worldY

    shopDrag_.worldX = worldX
    shopDrag_.worldY = worldY
    shopDrag_.placementValid = shopDrag_.activated
        and GearSystem.IsPlacementValid(
            worldX,
            worldY,
            radius,
            shopDrag_.gearType,
            gameData_.revenueGears,
            -1,
            mainGearX_,
            mainGearY_,
            mainGearRadius_,
            meshTolerance_
        )
end

---@param gearType string
---@param pointerId integer
---@param pointerType string
---@param screenX number
---@param screenY number
local function BeginShopGearDrag(
    gearType,
    pointerId,
    pointerType,
    screenX,
    screenY
)
    local logicalX, logicalY = UIToLogical(screenX, screenY)
    screenX = logicalX or screenX
    screenY = logicalY or screenY
    if shopDrag_.gearType ~= nil or activePointerId_ ~= nil then
        return
    end

    local definition = GearDefinitions.Get(gearType)
    if gameData_.coins < definition.purchaseCost then
        print(string.format(
            "[ShopDrag] 金币不足: type=%s, 当前=%d, 需要=%d",
            gearType,
            gameData_.coins,
            definition.purchaseCost
        ))
        return
    end

    shopDrag_.gearType = definition.type
    shopDrag_.pointerId = pointerId
    shopDrag_.pointerType = pointerType
    shopDrag_.startX = screenX
    shopDrag_.startY = screenY
    shopDrag_.screenX = screenX
    shopDrag_.screenY = screenY
    UpdateShopDragPreview(screenX, screenY, false)
    print("[ShopDrag] 开始拖出齿轮: " .. definition.type)
end

---@param pointerId integer
---@param pointerType string
---@param screenX number
---@param screenY number
---@param overCanvas boolean
local function MoveShopGearDrag(
    pointerId,
    pointerType,
    screenX,
    screenY,
    overCanvas
)
    local logicalX, logicalY = UIToLogical(screenX, screenY)
    screenX = logicalX or screenX
    screenY = logicalY or screenY
    if shopDrag_.pointerId ~= pointerId
        or shopDrag_.pointerType ~= pointerType then
        return
    end
    UpdateShopDragPreview(screenX, screenY, overCanvas)
end

---@param pointerId integer
---@param pointerType string
---@param screenX number
---@param screenY number
---@param overCanvas boolean
local function EndShopGearDrag(
    pointerId,
    pointerType,
    screenX,
    screenY,
    overCanvas
)
    local logicalX, logicalY = UIToLogical(screenX, screenY)
    screenX = logicalX or screenX
    screenY = logicalY or screenY
    if shopDrag_.pointerId ~= pointerId
        or shopDrag_.pointerType ~= pointerType then
        return
    end

    UpdateShopDragPreview(screenX, screenY, overCanvas)
    local gearType = shopDrag_.gearType
    if gearType ~= nil and shopDrag_.activated then
        local definition = GearDefinitions.Get(gearType)
        if gameData_.coins >= definition.purchaseCost then
            gameData_.coins = math.floor(
                gameData_.coins - definition.purchaseCost
            )
            local gearIndex = CreateRevenueGearAt(
                gearType,
                "商店拖拽购买",
                shopDrag_.worldX,
                shopDrag_.worldY
            )
            placementGearIndex_ = nil
            selectedGearIndex_ = gearIndex
            RebuildGearNetwork("商店拖拽放置", true)
            RefreshUI()
            MarkSaveDirty(0)
            SaveNow("拖拽购买收益齿轮")
            print(string.format(
                "[ShopDrag] 购买完成: type=%s, position=(%.1f, %.1f)",
                gearType,
                shopDrag_.worldX,
                shopDrag_.worldY
            ))
        end
    else
        print("[ShopDrag] 已取消，未扣除金币")
    end
    ClearShopDragState()
end

---@param pointerId integer
---@param pointerType string
local function CancelShopGearDrag(pointerId, pointerType)
    if shopDrag_.pointerId ~= pointerId
        or shopDrag_.pointerType ~= pointerType then
        return
    end
    print("[ShopDrag] 指针取消，未扣除金币")
    ClearShopDragState()
end

local function IsMommaFactoryUnlocked()
    return gameData_.unlockedBuildings.precisionFoundry == true
end

---@return integer
local function AdvanceMommaFactory(elapsedSeconds)
    if not IsMommaFactoryUnlocked() or elapsedSeconds <= 0 then
        return 0
    end

    local factory = GearDefinitions.MommaFactory
    if gameData_.mommaFactoryStock >= factory.maxStock then
        gameData_.mommaFactoryProgressSeconds = 0
        return 0
    end

    local cycleSeconds = GearDefinitions.GetMommaFactoryProductionSeconds(
        gameData_.ascensionCount
    )
    gameData_.mommaFactoryProgressSeconds =
        gameData_.mommaFactoryProgressSeconds + elapsedSeconds
    ---@type integer
    local produced = 0
    while gameData_.mommaFactoryProgressSeconds >= cycleSeconds
        and gameData_.mommaFactoryStock < factory.maxStock do
        gameData_.mommaFactoryProgressSeconds =
            gameData_.mommaFactoryProgressSeconds - cycleSeconds
        gameData_.mommaFactoryStock = gameData_.mommaFactoryStock + 1
        produced = produced + 1
    end
    if gameData_.mommaFactoryStock >= factory.maxStock then
        gameData_.mommaFactoryProgressSeconds = 0
    end
    return produced
end

local function AccumulateMommaFactory(now)
    if not IsMommaFactoryUnlocked() then
        gameData_.mommaFactoryLastTimestamp = now
        return
    end
    if gameData_.mommaFactoryLastTimestamp <= 0 then
        gameData_.mommaFactoryLastTimestamp = now
        return
    end

    local elapsed = math.floor(math.max(
        0,
        now - gameData_.mommaFactoryLastTimestamp
    ))
    local produced = math.floor(AdvanceMommaFactory(elapsed))
    gameData_.mommaFactoryLastTimestamp = now
    if produced > 0 then
        print(string.format(
            "[MommaFactory] 后台完成 %d 枚母齿轮，库存=%d/%d",
            produced,
            gameData_.mommaFactoryStock,
            GearDefinitions.MommaFactory.maxStock
        ))
    end
    MarkSaveDirty(produced > 0 and 0 or 30)
end

local function ClaimMommaFactoryGear()
    if not IsMommaFactoryUnlocked()
        or gameData_.mommaFactoryStock <= 0 then
        return
    end
    if placementGearIndex_ ~= nil then
        UI.Modal.Alert({
            title = "请先完成当前放置",
            message = "放好当前齿轮后，再领取工厂库存。",
            buttonText = "知道了",
        })
        return
    end

    gameData_.mommaFactoryStock = gameData_.mommaFactoryStock - 1
    CreateRevenueGearAt("momma", "巨型齿轮工厂")
    RefreshUI()
    MarkSaveDirty(0)
    SaveNow("领取工厂母齿轮")
end

local function UpgradeSelectedGear()
    if selectedGearIndex_ == nil then
        return
    end

    local gear = GetRevenueGear(selectedGearIndex_)
    local cost = GearDefinitions.GetUpgradeCost(gear.gearType, gear.level)
    if gameData_.coins < cost then
        print(string.format("[GearUpgrade] 金币不足: 当前=%d, 需要=%d", gameData_.coins, cost))
        return
    end

    gameData_.coins = gameData_.coins - cost
    gear.level = gear.level + 1
    RebuildGearNetwork("单齿轮升级", true)
    RefreshUI()
    MarkSaveDirty()
    SaveNow("单齿轮升级")

    print(string.format(
        "[GearUpgrade] id=%d, type=%s, level=%d, rpm=%.2f, torque=%.2f, income=%.2f",
        gear.id,
        gear.gearType,
        gear.level,
        gear.rpm,
        gear.torque,
        gear.incomePerSecond
    ))
end

local function UpgradeGlobal(upgradeType)
    ---@type integer
    local level
    if upgradeType == "income" then
        level = gameData_.globalIncomeLevel
    elseif upgradeType == "decay" then
        level = gameData_.decayReductionLevel
    else
        level = gameData_.offlineIncomeLevel
    end

    if upgradeType == "decay" and GetTransmissionDecay() <= 0.01001 then
        return
    end

    local cost = GearDefinitions.GetGlobalUpgradeCost(upgradeType, level)
    if gameData_.gearEssence < cost then
        print(string.format(
            "[EssenceUpgrade] 精华不足: type=%s, 当前=%d, 需要=%d",
            upgradeType,
            gameData_.gearEssence,
            cost
        ))
        return
    end

    gameData_.gearEssence = math.floor(gameData_.gearEssence - cost)
    if upgradeType == "income" then
        gameData_.globalIncomeLevel = math.floor(level + 1)
    elseif upgradeType == "decay" then
        gameData_.decayReductionLevel = math.floor(level + 1)
    else
        gameData_.offlineIncomeLevel = math.floor(level + 1)
    end
    RebuildGearNetwork("精华永久强化 " .. upgradeType, true)
    RefreshUI()
    MarkMetaChanged()
    SaveNow("精华永久强化")

    print(string.format(
        "[EssenceUpgrade] type=%s, essence=%d, incomeLevel=%d, decayLevel=%d, offlineLevel=%d, incomeMultiplier=%.2f, decay=%.3f, offlineMultiplier=%.2f",
        upgradeType,
        gameData_.gearEssence,
        gameData_.globalIncomeLevel,
        gameData_.decayReductionLevel,
        gameData_.offlineIncomeLevel,
        GetGlobalIncomeMultiplier(),
        GetTransmissionDecay(),
        GetOfflineMultiplier()
    ))
end

local function PurchaseMetaUnlock(category, unlockId)
    local definition = GearDefinitions.GetMetaUnlock(category, unlockId)
    local owned = category == "subMaps"
        and gameData_.unlockedSubMaps
        or gameData_.unlockedBuildings
    if definition == nil or owned[unlockId] == true then
        return
    end
    if gameData_.gearEssence < definition.cost then
        return
    end

    gameData_.gearEssence = gameData_.gearEssence - definition.cost
    owned[unlockId] = true
    if category == "buildings" and unlockId == "precisionFoundry" then
        gameData_.mommaFactoryLastTimestamp = os.time()
        gameData_.mommaFactoryProgressSeconds = 0
        RebuildGearNetwork("巨型齿轮工厂解锁", true)
    end
    RefreshUI()
    MarkMetaChanged()
    SaveNow("永久权限解锁")
    UI.Modal.Alert({
        title = "永久权限已解锁",
        message = definition.name
            .. " 已写入永久元进度，飞升后仍会保留。",
        buttonText = "知道了",
    })
    print(string.format(
        "[MetaUnlock] category=%s id=%s essence=%d",
        category,
        unlockId,
        gameData_.gearEssence
    ))
end

local function ShowAscensionToast(reward)
    ascensionToastTimer_ = 3.2
    ascensionToastLabel_:SetText(string.format(
        "飞升完成  +%d 齿轮精华\n永久增益已重新接入工坊",
        reward
    ))
    ascensionToastLabel_:SetOpacity(0)
    ascensionToastLabel_:SetVisible(true)
end

local function PerformAscension()
    local reward = GearDefinitions.GetAscensionReward(
        gameData_.runCoinsEarned
    )
    if reward <= 0 then
        return
    end

    if activePointerId_ ~= nil and CancelCanvasPointer then
        CancelCanvasPointer(activePointerId_, activePointerType_)
    end

    gameData_.gearEssence = gameData_.gearEssence + reward
    gameData_.ascensionCount = gameData_.ascensionCount + 1
    gameData_.coins = 0
    gameData_.runCoinsEarned = 0
    gameData_.clickLevel = 1
    gameData_.mainTorqueLevel = 0
    gameData_.mainCircleIncomeLevel = 0
    gameData_.nextGearId = 1
    gameData_.revenueGears = {}
    gameData_.autoDriveUnlocked = false
    gameData_.autoDriveLevel = 0
    gameData_.lastActiveTimestamp = os.time()
    gameData_.savedIncomePerSecond = 0
    gameData_.pendingOfflineCoins = 0
    gameData_.pendingOfflineSeconds = 0
    gameData_.growthWindowStartTimestamp = os.time()
    gameData_.growthWindowElapsedSeconds = 0
    gameData_.growthWindowStartIncome = 0
    gameData_.ascensionRecommendationShown = false

    selectedGearIndex_ = nil
    placementGearIndex_ = nil
    draggedGearIndex_ = nil
    incomeAccumulator_ = 0
    manualRotationRemaining_ = 0
    mainGearAngle_ = 0
    mainGearPulse_ = 0
    canvasScale_ = 1
    canvasOffsetX_ = 0
    canvasOffsetY_ = 0
    ascensionPanel_:SetVisible(false)

    RebuildGearNetwork("飞升重置", true)
    RefreshUI()
    MarkMetaChanged()
    SaveNow("飞升重置完成")
    ShowAscensionToast(reward)
    print(string.format(
        "[Ascension] 完成第%d次飞升，获得%d精华，永久精华=%d",
        gameData_.ascensionCount,
        reward,
        gameData_.gearEssence
    ))
end

local function RequestAscension()
    local reward = GearDefinitions.GetAscensionReward(
        gameData_.runCoinsEarned
    )
    if reward <= 0 then
        return
    end
    UI.Modal.Confirm({
        title = "确认飞升重构",
        message = string.format(
            "本次将获得 %d 齿轮精华。\n本局金币、摆放齿轮和临时等级将全部清空，永久强化与解锁权限保留。",
            reward
        ),
        confirmText = "确认飞升",
        cancelText = "返回检查",
        onConfirm = PerformAscension,
    })
end

local function OpenAscensionPanel()
    RefreshUI()
    ascensionPanel_:SetVisible(true)
end

local function CheckAscensionRecommendation()
    local now = os.time()
    if gameData_.growthWindowStartTimestamp <= 0 then
        gameData_.growthWindowStartTimestamp = now
        gameData_.growthWindowElapsedSeconds = 0
        gameData_.growthWindowStartIncome = totalIncomePerSecond_
        MarkSaveDirty()
        return
    end
    if gameData_.ascensionRecommendationShown
        or gameData_.growthWindowElapsedSeconds
            < GearDefinitions.Ascension.recommendationSeconds then
        return
    end

    local baseline = gameData_.growthWindowStartIncome
    local growthRate
    if baseline <= 0 then
        growthRate = totalIncomePerSecond_ > 0 and math.huge or 0
    else
        growthRate = (totalIncomePerSecond_ - baseline) / baseline
    end

    if growthRate < GearDefinitions.Ascension.recommendationGrowthRate then
        gameData_.ascensionRecommendationShown = true
        MarkSaveDirty()
        UI.Modal.Confirm({
            title = "工坊增长趋缓",
            message = string.format(
                "过去30分钟收益增速仅 %.1f%%，低于5%%。\n当前飞升预计获得 %d 齿轮精华，建议重构工坊开启下一轮。",
                growthRate * 100,
                GearDefinitions.GetAscensionReward(
                    gameData_.runCoinsEarned
                )
            ),
            confirmText = "查看飞升",
            cancelText = "继续经营",
            onConfirm = OpenAscensionPanel,
        })
    else
        gameData_.growthWindowStartTimestamp = now
        gameData_.growthWindowElapsedSeconds = 0
        gameData_.growthWindowStartIncome = totalIncomePerSecond_
        MarkSaveDirty()
    end
end

local function AccumulateOfflineReward(now)
    if gameData_.lastActiveTimestamp <= 0
        or gameData_.savedIncomePerSecond <= 0 then
        gameData_.lastActiveTimestamp = now
        return
    end

    local elapsed = math.floor(math.max(
        0,
        now - gameData_.lastActiveTimestamp
    ))
    local reward, effectiveSeconds =
        GearDefinitions.CalculateOfflineReward(
            gameData_.savedIncomePerSecond,
            elapsed,
            gameData_.offlineIncomeLevel
        )

    if reward > 0 then
        gameData_.pendingOfflineCoins = gameData_.pendingOfflineCoins + reward
        gameData_.pendingOfflineSeconds = gameData_.pendingOfflineSeconds
            + effectiveSeconds
        print(string.format(
            "[Offline] 累计离线奖励: elapsed=%d, effective=%d, baseIncome=%.2f, multiplier=%.2f, reward=%d",
            elapsed,
            effectiveSeconds,
            gameData_.savedIncomePerSecond,
            GetOfflineMultiplier(),
            reward
        ))
    end

    gameData_.lastActiveTimestamp = now
    MarkSaveDirty()
end

local function ClaimOfflineReward()
    local reward = gameData_.pendingOfflineCoins
    if reward <= 0 then
        return
    end

    CreditCoins(reward)
    gameData_.pendingOfflineCoins = 0
    gameData_.pendingOfflineSeconds = 0
    RefreshUI()
    MarkSaveDirty()
    SaveNow("领取离线收益")
    print(string.format(
        "[Offline] 已领取离线收益: +%d, 当前金币=%d",
        reward,
        gameData_.coins
    ))
end

local function AssembleLargeCompound(smallIndex, largeIndex)
    local smallGear = gameData_.revenueGears[smallIndex]
    local largeGear = gameData_.revenueGears[largeIndex]
    if not smallGear
        or not largeGear
        or smallGear.gearType ~= "small"
        or largeGear.gearType ~= "large" then
        print(string.format(
            "[AxleAssembly] 装配失败: smallIndex=%s, largeIndex=%s",
            tostring(smallIndex),
            tostring(largeIndex)
        ))
        return false
    end

    local smallId = smallGear.id
    local largeId = largeGear.id
    local definition = GearDefinitions.Get("large_compound")
    largeGear.gearType = definition.type
    largeGear.teeth = definition.teeth
    largeGear.radius = revenueGearRadius_ * definition.radiusScale
    UpdateGearNormalizedPosition(largeGear)

    table.remove(gameData_.revenueGears, smallIndex)
    if smallIndex < largeIndex then
        largeIndex = largeIndex - 1
    end

    selectedGearIndex_ = largeIndex
    placementGearIndex_ = nil
    RebuildGearNetwork("大型齿轮同轴装配", true)
    RefreshUI()
    MarkSaveDirty(0)
    SaveNow("大型齿轮同轴装配")
    print(string.format(
        "[AxleAssembly] 装配完成: 消耗小型齿轮 #%d, 大型齿轮 #%d 转换为 48/16 齿同轴复合齿轮",
        smallId,
        largeId
    ))
    return true
end

local function FindGearAt(x, y)
    for index = #gameData_.revenueGears, 1, -1 do
        local gear = gameData_.revenueGears[index]
        local hitRadius = gear.radius * 1.18
        if DistanceSquared(x, y, gear.x, gear.y) <= hitRadius * hitRadius then
            return index
        end
    end

    return nil
end

local function IsMainGearAt(x, y)
    local hitRadius = mainGearRadius_ * 1.08
    return DistanceSquared(x, y, mainGearX_, mainGearY_) <= hitRadius * hitRadius
end

local function ClearPointerState()
    activePointerId_ = nil
    activePointerType_ = nil
    draggedGearIndex_ = nil
    dragActivated_ = false
    dragPlacementValid_ = true
    dragSnapValid_ = false
    dragSnapRing_ = nil
    dragAnchorRing_ = nil
    axleAssemblyTargetIndex_ = nil
    canvasPanning_ = false
    pointerStartedOnMainGear_ = false
    pointerMoved_ = false
end

local function BeginCanvasPointer(pointerId, pointerType, screenX, screenY)
    if activePointerId_ ~= nil or pinchActive_ then
        return
    end

    local worldX, worldY = ScreenToWorld(screenX, screenY)
    local enteringPlacement = placementGearIndex_ ~= nil
    local gearIndex = placementGearIndex_
    if gearIndex then
        local placementGear = gameData_.revenueGears[gearIndex]
        if placementGear then
            placementGear.x = worldX
            placementGear.y = worldY
            UpdateGearNormalizedPosition(placementGear)
            RebuildGearNetwork("购买后开始放置", false)
        else
            gearIndex = nil
        end
        placementGearIndex_ = nil
    else
        gearIndex = FindGearAt(worldX, worldY)
    end
    local onMainGear = IsMainGearAt(worldX, worldY)

    activePointerId_ = pointerId
    activePointerType_ = pointerType
    draggedGearIndex_ = gearIndex
    pointerStartedOnMainGear_ = onMainGear and gearIndex == nil
    pointerMoved_ = enteringPlacement
    dragActivated_ = enteringPlacement
    canvasPanning_ = false
    pointerStartX_ = screenX
    pointerStartY_ = screenY
    pointerLastX_ = screenX
    pointerLastY_ = screenY

    if gearIndex then
        local gear = GetRevenueGear(gearIndex)
        dragOffsetX_ = gear.x - worldX
        dragOffsetY_ = gear.y - worldY
        dragOriginalX_ = gear.x
        dragOriginalY_ = gear.y
        print(string.format("[Input] 开始拖拽齿轮 id=%d", gear.id))
    end
end

local function MoveCanvasPointer(pointerId, pointerType, screenX, screenY)
    if activePointerId_ ~= pointerId
        or activePointerType_ ~= pointerType
        or pinchActive_ then
        return
    end

    local movedBeyondThreshold = DistanceSquared(
        screenX,
        screenY,
        pointerStartX_,
        pointerStartY_
    ) > CONFIG.DragThreshold ^ 2
    if movedBeyondThreshold then
        pointerMoved_ = true
    end

    if not draggedGearIndex_ then
        if movedBeyondThreshold then
            canvasPanning_ = true
            canvasOffsetX_ = canvasOffsetX_ + screenX - pointerLastX_
            canvasOffsetY_ = canvasOffsetY_ + screenY - pointerLastY_
        end
        pointerLastX_ = screenX
        pointerLastY_ = screenY
        return
    end

    if not dragActivated_ then
        if not movedBeyondThreshold then
            return
        end
        dragActivated_ = true
    end

    local worldX, worldY = ScreenToWorld(screenX, screenY)
    local gear = GetRevenueGear(draggedGearIndex_)
    local candidateX = worldX + dragOffsetX_
    local candidateY = worldY + dragOffsetY_
    local axleTargetIndex, axleX, axleY =
        GearSystem.FindAxleAssemblyTarget(
            gear.gearType,
            candidateX,
            candidateY,
            gameData_.revenueGears,
            draggedGearIndex_,
            snapTolerance_
        )

    axleAssemblyTargetIndex_ = axleTargetIndex
    if axleTargetIndex ~= nil then
        candidateX = axleX
        candidateY = axleY
        dragSnapValid_ = false
        dragSnapRing_ = "axle"
        dragAnchorRing_ = "axle"
        dragPlacementValid_ = true
    else
        local snapped
        local snappedRing
        local anchorRing
        candidateX,
            candidateY,
            snapped,
            snappedRing,
            anchorRing = GearSystem.FindSnapPosition(
            candidateX,
            candidateY,
            gear.radius,
            gameData_.revenueGears,
            draggedGearIndex_,
            mainGearX_,
            mainGearY_,
            mainGearRadius_,
            snapTolerance_,
            gear.gearType
        )

        dragSnapValid_ = snapped == true
        dragSnapRing_ = snappedRing
        dragAnchorRing_ = anchorRing
        dragPlacementValid_ = GearSystem.IsPlacementValid(
            candidateX,
            candidateY,
            gear.radius,
            gear.gearType,
            gameData_.revenueGears,
            draggedGearIndex_,
            mainGearX_,
            mainGearY_,
            mainGearRadius_,
            meshTolerance_
        )
    end

    gear.x = candidateX
    gear.y = candidateY
    UpdateGearNormalizedPosition(gear)
    RebuildGearNetwork("拖拽中", false)
end

local function EndCanvasPointer(pointerId, pointerType, x, y)
    if activePointerId_ ~= pointerId or activePointerType_ ~= pointerType then
        return
    end

    MoveCanvasPointer(pointerId, pointerType, x, y)

    if draggedGearIndex_ then
        local gear = GetRevenueGear(draggedGearIndex_)
        local gearId = gear.id

        if dragActivated_ and axleAssemblyTargetIndex_ ~= nil then
            local targetIndex = axleAssemblyTargetIndex_
            local assembled = AssembleLargeCompound(
                draggedGearIndex_,
                targetIndex
            )
            if not assembled then
                gear.x = dragOriginalX_
                gear.y = dragOriginalY_
                UpdateGearNormalizedPosition(gear)
                RebuildGearNetwork("同轴装配失败回退", true)
            end
            ClearPointerState()
            return
        end

        if dragActivated_ then
            if not dragPlacementValid_ then
                gear.x = dragOriginalX_
                gear.y = dragOriginalY_
                UpdateGearNormalizedPosition(gear)
                RebuildGearNetwork("无效放置回退", true)
                print(string.format(
                    "[Input] 无效放置，已恢复齿轮 id=%d 原位置",
                    gearId
                ))
            else
                UpdateGearNormalizedPosition(gear)
                RebuildGearNetwork("拖拽结束", true)
                MarkSaveDirty()
                SaveNow("齿轮位置变更")
                print(string.format(
                    "[Input] 结束拖拽齿轮 id=%d, position=(%.1f, %.1f), connected=%s, snap=%s/%s",
                    gearId,
                    gear.x,
                    gear.y,
                    tostring(gear.connected),
                    tostring(dragSnapRing_),
                    tostring(dragAnchorRing_)
                ))
            end
        else
            selectedGearIndex_ = draggedGearIndex_
            RefreshSelectedGearUI()
            print("[Input] 选中齿轮 id=" .. tostring(gearId))
        end
    elseif pointerStartedOnMainGear_ and not pointerMoved_ then
        AddCoinsFromMainGear()
    elseif not canvasPanning_ then
        selectedGearIndex_ = nil
        RefreshSelectedGearUI()
    end

    ClearPointerState()
end

CancelCanvasPointer = function(pointerId, pointerType)
    if activePointerId_ ~= pointerId or activePointerType_ ~= pointerType then
        return
    end

    if draggedGearIndex_ and dragActivated_ then
        local gear = GetRevenueGear(draggedGearIndex_)
        gear.x = dragOriginalX_
        gear.y = dragOriginalY_
        UpdateGearNormalizedPosition(gear)
        RebuildGearNetwork("拖拽取消", true)
        print("[Input] 拖拽被取消，已恢复原位置: id=" .. tostring(gear.id))
    end

    ClearPointerState()
end

function IsCanvasAtUIPosition(uiX, uiY)
    local target = UI.FindWidgetAt(uiX, uiY)
    while target do
        if target.id == "canvasInputArea" then
            return true
        end
        target = target.parent
    end
    return false
end

function FindShopGearTypeAtUIPosition(uiX, uiY)
    local target = UI.FindWidgetAt(uiX, uiY)
    while target do
        if target.props and target.props.shopGearType then
            return target.props.shopGearType
        end
        target = target.parent
    end
    return nil
end

function HandleMouseButtonDown(eventType, eventData)
    if eventData:GetInt("Button") ~= MOUSEB_LEFT
        or shopDrag_.gearType ~= nil then
        return
    end
    local uiScale = math.max(UI.GetScale(), 1)
    local uiX = eventData:GetInt("X") / uiScale
    local uiY = eventData:GetInt("Y") / uiScale
    local gearType = FindShopGearTypeAtUIPosition(uiX, uiY)
    if gearType then
        BeginShopGearDrag(gearType, 0, "mouse", uiX, uiY)
    end
end

function HandleTouchBegin(eventType, eventData)
    if shopDrag_.gearType ~= nil then
        return
    end
    local uiScale = math.max(UI.GetScale(), 1)
    local uiX = eventData:GetInt("X") / uiScale
    local uiY = eventData:GetInt("Y") / uiScale
    local gearType = FindShopGearTypeAtUIPosition(uiX, uiY)
    if gearType then
        BeginShopGearDrag(
            gearType,
            eventData:GetInt("TouchID"),
            "touch",
            uiX,
            uiY
        )
    end
end

function HandleShopPointerMove(event)
    return
end

function HandleShopPointerUp(event)
    return
end

function HandleShopPointerCancel(event)
    return
end

function HandleCanvasPointerDown(event)
    local screenX, screenY = UIToLogical(event.x, event.y)
    if event.pointerType == "touch" then
        activeTouches_[event.pointerId] = { x = screenX, y = screenY }
        local firstId, secondId = GetTouchPair()
        if firstId ~= nil and secondId ~= nil then
            BeginPinch()
            return
        end
    elseif not event:IsPrimaryAction() then
        return
    end

    BeginCanvasPointer(
        event.pointerId,
        event.pointerType,
        screenX,
        screenY
    )
end

local function HandleCanvasPointerMove(event)
    local screenX, screenY = UIToLogical(event.x, event.y)
    if event.pointerType == "touch" and activeTouches_[event.pointerId] then
        activeTouches_[event.pointerId].x = screenX
        activeTouches_[event.pointerId].y = screenY
        if pinchActive_ then
            UpdatePinch()
            return
        end
    end

    MoveCanvasPointer(
        event.pointerId,
        event.pointerType,
        screenX,
        screenY
    )
end

local function HandleCanvasPointerUp(event)
    local screenX, screenY = UIToLogical(event.x, event.y)
    if event.pointerType == "touch" then
        local wasPinching = pinchActive_
        activeTouches_[event.pointerId] = nil
        EndPinchIfNeeded()
        if wasPinching then
            return
        end
    end

    EndCanvasPointer(
        event.pointerId,
        event.pointerType,
        screenX,
        screenY
    )
end

local function HandleCanvasPointerCancel(event)
    if event.pointerType == "touch" then
        activeTouches_[event.pointerId] = nil
        EndPinchIfNeeded()
    end
    CancelCanvasPointer(event.pointerId, event.pointerType)
end

local function CreateUI()
    local refs = GameUI.Create({
        title = CONFIG.Title,
        upgradeClickValue = UpgradeClickValue,
        shopGearDragStart = BeginShopGearDrag,
        shopGearDragMove = MoveShopGearDrag,
        shopGearDragEnd = EndShopGearDrag,
        shopGearDragCancel = CancelShopGearDrag,
        showAutoDriveRequirement = ShowAutoDriveRequirement,
        upgradeMainTorque = UpgradeMainTorque,
        upgradeMainCircleIncome = UpgradeMainCircleIncome,
        upgradeSelectedGear = UpgradeSelectedGear,
        closeGearDetails = function()
            selectedGearIndex_ = nil
            RefreshSelectedGearUI()
        end,
        upgradeGlobal = UpgradeGlobal,
        refreshGlobalUpgradeUI = RefreshGlobalUpgradeUI,
        purchaseMetaUnlock = PurchaseMetaUnlock,
        openAscensionPanel = OpenAscensionPanel,
        requestAscension = RequestAscension,
        claimOfflineReward = ClaimOfflineReward,
        claimMommaFactoryGear = ClaimMommaFactoryGear,
        canvasPointerDown = HandleCanvasPointerDown,
        canvasPointerMove = HandleCanvasPointerMove,
        canvasPointerUp = HandleCanvasPointerUp,
        canvasPointerCancel = HandleCanvasPointerCancel,
    })

    uiRoot_, coinLabel_, clickValueLabel_, revenueLabel_, levelLabel_, shopInfoLabel_ =
        refs.root, refs.coinLabel, refs.clickValueLabel, refs.revenueLabel, refs.levelLabel, refs.shopInfoLabel
    essenceLabel_, powerStatusLabel_, loadGaugeLabel_, loadProgressBar_ =
        refs.essenceLabel, refs.powerStatusLabel, refs.loadGaugeLabel, refs.loadProgressBar
    upgradeButton_, mainTorqueUpgradeButton_, mainCircleIncomeUpgradeButton_ =
        refs.upgradeButton, refs.mainTorqueUpgradeButton, refs.mainCircleIncomeUpgradeButton
    buySmallGearButton_, buySmallGearPriceLabel_, buyMediumGearButton_, buyMediumGearPriceLabel_ =
        refs.buySmallGearButton, refs.buySmallGearPriceLabel, refs.buyMediumGearButton, refs.buyMediumGearPriceLabel
    buyLargeGearButton_, buyLargeGearPriceLabel_, buyCompoundGearButton_, buyCompoundGearPriceLabel_, autoDriveButton_ =
        refs.buyLargeGearButton, refs.buyLargeGearPriceLabel, refs.buyCompoundGearButton, refs.buyCompoundGearPriceLabel, refs.autoDriveButton
    buyMommaGearButton_, buyMommaGearPriceLabel_, factoryStatusLabel_, factoryClaimButton_ =
        refs.buyMommaGearButton, refs.buyMommaGearPriceLabel, refs.factoryStatusLabel, refs.factoryClaimButton
    gearDetailsPanel_, gearDetailsTitleLabel_, gearDetailsStatusLabel_, gearDetailsStatsLabel_, gearDetailsUpgradeLabel_ =
        refs.gearDetailsPanel, refs.gearDetailsTitleLabel, refs.gearDetailsStatusLabel, refs.gearDetailsStatsLabel, refs.gearDetailsUpgradeLabel
    gearDetailsEssenceLabel_ = refs.gearDetailsEssenceLabel
    gearUpgradeButton_, gearDetailsCloseButton_ = refs.gearUpgradeButton, refs.gearDetailsCloseButton
    globalUpgradePanel_, globalUpgradeSummaryLabel_, globalIncomeUpgradeButton_, decayUpgradeButton_, offlineUpgradeButton_ =
        refs.globalUpgradePanel, refs.globalUpgradeSummaryLabel, refs.globalIncomeUpgradeButton, refs.decayUpgradeButton, refs.offlineUpgradeButton
    globalUpgradeOpenButton_, globalUpgradeCloseButton_ = refs.globalUpgradeOpenButton, refs.globalUpgradeCloseButton
    unlockMapButton_, unlockBuildingButton_ = refs.unlockMapButton, refs.unlockBuildingButton
    ascensionPanel_, ascensionOpenButton_, ascensionRewardLabel_, ascensionProgressLabel_ =
        refs.ascensionPanel, refs.ascensionOpenButton, refs.ascensionRewardLabel, refs.ascensionProgressLabel
    ascensionConfirmButton_, ascensionToastLabel_ = refs.ascensionConfirmButton, refs.ascensionToastLabel
    offlineRewardPanel_, offlineRewardLabel_, claimOfflineButton_, canvasInputArea_ =
        refs.offlineRewardPanel, refs.offlineRewardLabel, refs.claimOfflineButton, refs.canvasInputArea

    RefreshLayout()
    RefreshUI()
end

function Start()
    graphics.windowTitle = CONFIG.Title
    input.mouseMode = MM_ABSOLUTE
    input.mouseVisible = true

    print("[Game] 开始初始化 " .. CONFIG.Title)
    ---@type GearWorkshopGameData
    local loadedData = SaveSystem.Load()
    gameData_ = loadedData

    if GearDefinitions.CanUnlockAutoDrive(
        gameData_.mainTorqueLevel
    ) and not gameData_.autoDriveUnlocked then
        gameData_.autoDriveUnlocked = true
        gameData_.autoDriveLevel = 1
        MarkSaveDirty()
        print("[Drive] 已根据主轴扭矩等级修复自动驱动解锁状态")
    end

    for _, gear in ipairs(gameData_.revenueGears) do
        local definition = GearDefinitions.Get(gear.gearType)
        gear.gearType = definition.type
        gear.level = gear.level or 1
        gear.x = 0
        gear.y = 0
        gear.radius = 1
        gear.teeth = definition.teeth
        gear.angle = 0
        gear.connected = false
        gear.meshed = false
        gear.jammed = false
        gear.spinDirection = 0
        gear.rpm = 0
        gear.rpmRatio = 0
        gear.torque = 0
        gear.incomePerSecond = 0
        gear.transmissionDepth = 0
        gear.parentIndex = nil
        gear.inputRing = nil
        gear.load = 0
        gear.layerSpeedFactor = 0
        gear.speedCapped = false
        gear.overloaded = false
    end

    print(string.format(
        "[Game] 初始数据: coins=%d, clickLevel=%d, revenueGears=%d",
        gameData_.coins,
        gameData_.clickLevel,
        #gameData_.revenueGears
    ))

    vg_ = nvgCreate(1)
    GearRenderer.Initialize(vg_)

    UI.Init({
        fonts = {
            {
                family = "sans",
                weights = {
                    normal = "Fonts/NotoSansCJKsc-Regular.otf",
                    bold = "Fonts/NotoSansCJKsc-Regular.otf",
                },
            },
        },
        scale = UI.Scale.DEFAULT,
    })

    CreateUI()
    AccumulateOfflineReward(os.time())
    AccumulateMommaFactory(os.time())
    RefreshUI()
    LoadMetaFromCloud()

    SubscribeToEvent(vg_, "NanoVGRender", "HandleNanoVGRender")
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("ScreenMode", "HandleScreenMode")
    SubscribeToEvent("MouseButtonDown", "HandleMouseButtonDown")
    SubscribeToEvent("TouchBegin", "HandleTouchBegin")
    SubscribeToEvent("MouseMove", "HandleMouseMove")
    SubscribeToEvent("MouseButtonUp", "HandleMouseButtonUp")
    SubscribeToEvent("TouchMove", "HandleTouchMove")
    SubscribeToEvent("TouchEnd", "HandleTouchEnd")
    SubscribeToEvent("AppWillEnterBackground", "HandleAppBackground")
    SubscribeToEvent("AppDidEnterBackground", "HandleAppBackground")
    SubscribeToEvent("AppWillEnterForeground", "HandleAppForeground")
    SubscribeToEvent("ExitRequested", "HandleExitRequested")

    print("[Game] 初始化完成，等待购买并摆放收益齿轮")
end

function Stop()
    print("[Game] 正在停止")
    MarkSaveDirty(0)
    SaveNow("游戏停止")
    UI.Shutdown()
    nvgDelete(vg_)
end

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local timeStep = eventData:GetFloat("TimeStep")
    warningPhase_ = warningPhase_ + timeStep
    gameData_.growthWindowElapsedSeconds =
        gameData_.growthWindowElapsedSeconds + timeStep
    local drivetrainRunning = gameData_.autoDriveUnlocked
        and not networkState_.jammed
        and not networkState_.overloaded
    if drivetrainRunning then
        mainGearAngle_ = mainGearAngle_
            + timeStep * GetMainRPM() * math.pi * 2 / 60
    elseif manualRotationRemaining_ > 0 then
        local manualStep = math.min(
            manualRotationRemaining_,
            timeStep * math.pi * 5
        )
        mainGearAngle_ = mainGearAngle_ + manualStep
        manualRotationRemaining_ = manualRotationRemaining_ - manualStep
    end
    mainGearPulse_ = math.max(0, mainGearPulse_ - timeStep * 4.8)

    if ascensionToastTimer_ > 0 then
        ascensionToastTimer_ = math.max(0, ascensionToastTimer_ - timeStep)
        local elapsed = 3.2 - ascensionToastTimer_
        ---@type number
        local opacity = 1.0
        if elapsed < 0.35 then
            opacity = elapsed / 0.35
        elseif ascensionToastTimer_ < 0.55 then
            opacity = ascensionToastTimer_ / 0.55
        end
        ascensionToastLabel_:SetOpacity(math.max(0, math.min(1, opacity)))
        if ascensionToastTimer_ <= 0 then
            ascensionToastLabel_:SetVisible(false)
        end
    end

    recommendationCheckTimer_ = recommendationCheckTimer_ - timeStep
    if recommendationCheckTimer_ <= 0 then
        recommendationCheckTimer_ = 5.0
        CheckAscensionRecommendation()
    end

    factoryUpdateTimer_ = factoryUpdateTimer_ - timeStep
    if factoryUpdateTimer_ <= 0 then
        factoryUpdateTimer_ = 1.0
        if IsMommaFactoryUnlocked() then
            local produced = math.floor(AdvanceMommaFactory(1))
            gameData_.mommaFactoryLastTimestamp = os.time()
            if produced > 0 then
                print(string.format(
                    "[MommaFactory] 完成母齿轮，库存=%d/%d",
                    gameData_.mommaFactoryStock,
                    GearDefinitions.MommaFactory.maxStock
                ))
                MarkSaveDirty(0)
            end
            RefreshUI()
        end
    end

    for _, gear in ipairs(gameData_.revenueGears) do
        if gear.connected then
            local radiansPerSecond = gear.rpm * math.pi * 2 / 60
            gear.angle = gear.angle + timeStep * radiansPerSecond * gear.spinDirection
        end
    end

    if totalIncomePerSecond_ > 0 then
        incomeAccumulator_ = incomeAccumulator_ + totalIncomePerSecond_ * timeStep
        local earnedCoins = math.floor(incomeAccumulator_)
        if earnedCoins > 0 then
            incomeAccumulator_ = incomeAccumulator_ - earnedCoins
            CreditCoins(earnedCoins)
            print(string.format(
                "[Economy] 自动收益结算: +%d, 当前产能=%.2f/s, 当前金币=%d",
                earnedCoins,
                totalIncomePerSecond_,
                gameData_.coins
            ))
            RefreshUI()
            MarkSaveDirty(CONFIG.IncomeSaveDelay)
        end
    end

    if saveDirty_ then
        saveTimer_ = saveTimer_ - timeStep
        if saveTimer_ <= 0 then
            SaveNow("自动保存计时完成")
        end
    end
end

function HandleNanoVGRender()
    nvgBeginFrame(vg_, logicalWidth_, logicalHeight_, dpr_)
    GearRenderer.DrawBackground(
        vg_,
        logicalWidth_,
        logicalHeight_,
        mainGearX_ * canvasScale_ + canvasOffsetX_,
        mainGearY_ * canvasScale_ + canvasOffsetY_,
        mainGearRadius_ * canvasScale_
    )
    nvgSave(vg_)
    nvgTranslate(vg_, canvasOffsetX_, canvasOffsetY_)
    nvgScale(vg_, canvasScale_, canvasScale_)
    local factoryUnlocked = IsMommaFactoryUnlocked()
    local factoryCycle = GearDefinitions.GetMommaFactoryProductionSeconds(
        gameData_.ascensionCount
    )
    GearRenderer.DrawFactory(
        vg_,
        mainGearX_ - mainGearRadius_ * 2.65,
        mainGearY_ - mainGearRadius_ * 2.35,
        mainGearRadius_ * 2.1,
        mainGearRadius_ * 1.35,
        factoryUnlocked,
        factoryUnlocked
            and gameData_.mommaFactoryStock
                < GearDefinitions.MommaFactory.maxStock,
        gameData_.mommaFactoryStock,
        GearDefinitions.MommaFactory.maxStock,
        factoryCycle > 0
            and gameData_.mommaFactoryProgressSeconds / factoryCycle
            or 0,
        warningPhase_
    )
    GearRenderer.DrawConnections(vg_, connections_, gameData_.revenueGears, mainGearX_, mainGearY_)
    local drivetrainRunning = gameData_.autoDriveUnlocked
        and not networkState_.jammed
        and not networkState_.overloaded
    local mainSpeedCapped = drivetrainRunning
        and IsMainSpeedCapped()
    local visualAngles = GearRenderer.ResolveVisualAngles(
        gameData_.revenueGears,
        connections_,
        mainGearX_,
        mainGearY_,
        mainGearAngle_
    )
    local layeredIndices = GearRenderer.GetLayeredGearIndices(
        gameData_.revenueGears,
        draggedGearIndex_
    )

    GearRenderer.DrawMainGear(
        vg_,
        mainGearX_,
        mainGearY_,
        mainGearRadius_,
        mainGearAngle_,
        mainGearPulse_,
        drivetrainRunning,
        mainSpeedCapped,
        warningPhase_
    )

    for _, index in ipairs(layeredIndices) do
        GearRenderer.DrawRevenueGear(
            vg_,
            GetRevenueGear(index),
            false,
            index == selectedGearIndex_,
            visualAngles[index]
        )
    end

    if draggedGearIndex_ then
        GearRenderer.DrawRevenueGear(
            vg_,
            GetRevenueGear(draggedGearIndex_),
            true,
            draggedGearIndex_ == selectedGearIndex_,
            visualAngles[draggedGearIndex_],
            dragPlacementValid_
        )
    end

    if shopDrag_.gearType ~= nil and shopDrag_.activated then
        local definition = GearDefinitions.Get(shopDrag_.gearType)
        GearRenderer.DrawRevenueGear(
            vg_,
            {
                gearType = definition.type,
                x = shopDrag_.worldX,
                y = shopDrag_.worldY,
                radius = revenueGearRadius_ * definition.radiusScale,
                teeth = definition.teeth,
                angle = 0,
                connected = false,
                meshed = false,
                jammed = false,
            },
            true,
            false,
            0,
            shopDrag_.placementValid
        )
    end

    nvgRestore(vg_)
    nvgEndFrame(vg_)
end

function HandleScreenMode()
    RefreshLayout()
end

---@param eventType string
---@param eventData MouseMoveEventData
function HandleMouseMove(eventType, eventData)
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 1)
        local uiX = eventData:GetInt("X") / uiScale
        local uiY = eventData:GetInt("Y") / uiScale
        local logicalX, logicalY = UIToLogical(uiX, uiY)
        MoveShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            logicalX,
            logicalY,
            IsCanvasAtUIPosition(uiX, uiY)
        )
        return
    end
    if activePointerType_ ~= "mouse" then
        return
    end
    local x, y = PhysicalToLogical(eventData:GetInt("X"), eventData:GetInt("Y"))
    MoveCanvasPointer(0, "mouse", x, y)
end

---@param eventType string
---@param eventData MouseButtonUpEventData
function HandleMouseButtonUp(eventType, eventData)
    if eventData:GetInt("Button") ~= MOUSEB_LEFT then
        return
    end
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 1)
        local uiX = eventData:GetInt("X") / uiScale
        local uiY = eventData:GetInt("Y") / uiScale
        local logicalX, logicalY = UIToLogical(uiX, uiY)
        EndShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            logicalX,
            logicalY,
            IsCanvasAtUIPosition(uiX, uiY)
        )
        return
    end
    if activePointerType_ ~= "mouse" then
        return
    end
    local x, y = PhysicalToLogical(eventData:GetInt("X"), eventData:GetInt("Y"))
    EndCanvasPointer(0, "mouse", x, y)
end

---@param eventType string
---@param eventData TouchMoveEventData
function HandleTouchMove(eventType, eventData)
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 1)
        local uiX = eventData:GetInt("X") / uiScale
        local uiY = eventData:GetInt("Y") / uiScale
        local logicalX, logicalY = UIToLogical(uiX, uiY)
        MoveShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            logicalX,
            logicalY,
            IsCanvasAtUIPosition(uiX, uiY)
        )
        return
    end
    if activePointerType_ ~= "touch" then
        return
    end
    local touchId = eventData:GetInt("TouchID")
    local x, y = PhysicalToLogical(eventData:GetInt("X"), eventData:GetInt("Y"))
    MoveCanvasPointer(touchId, "touch", x, y)
end

---@param eventType string
---@param eventData TouchEndEventData
function HandleTouchEnd(eventType, eventData)
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 1)
        local uiX = eventData:GetInt("X") / uiScale
        local uiY = eventData:GetInt("Y") / uiScale
        local logicalX, logicalY = UIToLogical(uiX, uiY)
        EndShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            logicalX,
            logicalY,
            IsCanvasAtUIPosition(uiX, uiY)
        )
        return
    end
    if activePointerType_ ~= "touch" then
        return
    end
    local touchId = eventData:GetInt("TouchID")
    local x, y = PhysicalToLogical(eventData:GetInt("X"), eventData:GetInt("Y"))
    EndCanvasPointer(touchId, "touch", x, y)
end

function HandleAppBackground()
    if activePointerId_ ~= nil then
        CancelCanvasPointer(activePointerId_, activePointerType_)
    end
    MarkSaveDirty(0)
    SaveNow("应用进入后台")
end

function HandleAppForeground()
    local now = os.time()
    AccumulateOfflineReward(now)
    AccumulateMommaFactory(now)
    RebuildGearNetwork("后台生产结算", true)
    RefreshUI()
    SaveNow("应用回到前台")
end

function HandleExitRequested()
    MarkSaveDirty(0)
    SaveNow("收到退出请求")
end
