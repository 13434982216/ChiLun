local UI = require("urhox-libs/UI")
ImageCache = require("urhox-libs/UI/Core/ImageCache")
local GameUI = require("GameUI")
HomeUI = require("HomeUI")
local SaveSystem = require("SaveSystem")
local GearSystem = require("GearSystem")
local GearRenderer = require("GearRenderer")
local GearDefinitions = require("GearDefinitions")
local MetaProgression = require("MetaProgression")
local TutorialRuntime = require("TutorialRuntime")
GearGeometryMigration = require("GearGeometryMigration")
LoadingScreen = require("LoadingScreen")

local CONFIG = {
    Title = "齿轮工坊",
    AutoSaveDelay = 0.35,
    IncomeSaveDelay = 5.0,
    DragThreshold = 10,
    ShopClickTolerance = 16,
    RecycleLongPressSeconds = 0.45,
    RecycleRefundRate = 0.50,
    IncomeLeaderboardKey = "gear_workshop_income_per_second_v1",
    IncomeLeaderboardLimit = 100,
    IncomeLeaderboardSyncDelay = 15.0,
    IncomeLeaderboardScale = 100,
    TutorialTestAccountKey = "gear_workshop_tutorial_test_account_v1",
}

local responsiveLayout_ = {
    mode = "landscape",
    apply = nil,
    rebuild = nil,
    leftRailWidth = 92,
    rightRailWidth = 104,
    canvasLeft = 0,
    canvasRight = 1,
    screenLogicalWidth = 1,
    screenLogicalHeight = 1,
    screenUIWidth = 1,
    screenUIHeight = 1,
    rotatePortrait = false,
    clickUpgradeConfirmButton = nil,
    clickUpgradeResultLabel = nil,
    refreshMainUpgradeDetails = nil,
    hideMainUpgradeDetails = nil,
    setUpgradeRailUnlocked = nil,
    setPermanentUpgradeRevealed = nil,
    setGearWarehouseUnlocked = nil,
    setShopGearRevealed = nil,
    pointerObject = nil,
    gearAudioScene = nil,
    gearAudioSource = nil,
    gearAudioSound = nil,
    gearAudioBaseFrequency = 0,
    gearAudioFrequency = 0,
    gearAudioGain = 0,
    manualMainGearTurnsRemaining = 0,
    tutorial = nil,
    tutorialRoot = nil,
    tutorialRefs = {},
    tutorialTestAccount = false,
    tutorialTestAccountChecked = false,
    lubricationUIRefreshTimer = 0,
    lubricantCooldownDisplaySecond = -1,
    mainOilEffectRemaining = 0,
    recycleDropZone = nil,
    recycleRefundLabel = nil,
    recycleHoldElapsed = 0,
    recycleLongPressArmed = false,
    recycleLongPressTriggered = false,
    recycleHovering = false,
    recyclePointerX = 0,
    recyclePointerY = 0,
    idleAdRequest = {
        inFlight = false,
        token = 0,
        deadline = 0,
    },
    homeVisible = true,
    homeLeaderboardLoading = false,
    homeLeaderboardRequestId = 0,
    homeLeaderboardEntries = {},
    homeLeaderboardNicknameRetryAt = 0,
    homeLeaderboardNicknameRetryCount = 0,
    homeLeaderboardNicknameEntries = nil,
    homeLeaderboardNicknameUserIds = nil,
    homeAssetText = "",
    homeUI = nil,
    incomeLeaderboardWritePending = false,
    incomeLeaderboardDirty = true,
    lastIncomeLeaderboardValue = -1,
    incomeLeaderboardSyncTimer = 0,
    faultIndicator = {
        visible = false,
        screenX = 0,
        screenY = 0,
        targetX = 0,
        targetY = 0,
        angle = 0,
        reason = "",
        targetType = "",
        targetId = nil,
    },
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
---@field anchorX number|nil
---@field anchorY number|nil
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
---@field turnProgress number
---@field lubricationRemaining number
---@field lubricated boolean
---@field maintenanceJammed boolean
---@field autonomous boolean
---@field patrolTargetCursor integer
---@field patrolState string
---@field patrolOrbitAngle number
---@field patrolOrbitTravel number
---@field oilEffectRemaining number
---@field transmissionDepth integer
---@field parentIndex integer|nil
---@field inputRing string|nil
---@field load number
---@field layerSpeedFactor number
---@field speedCapped boolean
---@field overloaded boolean
---@field purchaseCostPaid integer|nil

---@class GearWorkshopGameData
---@field geometryVersion integer
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
---@field gearPurchaseCounts table<string, integer>
---@field permanentContentUnlocks table<string, boolean>
---@field lubricantCooldownRemaining number
---@field autoDriveUnlocked boolean
---@field gearWarehousePermanentlyUnlocked boolean
---@field upgradeRailPermanentlyUnlocked boolean
---@field autoDriveLevel integer
---@field globalIncomeLevel integer
---@field decayReductionLevel integer
---@field offlineIncomeLevel integer
---@field lastActiveTimestamp integer
---@field savedIncomePerSecond number
---@field pendingOfflineCoins integer
---@field pendingOfflineSeconds integer
---@field idleAdDayKey integer
---@field idleAdWatchCount integer
---@field idleEligibleUntil integer
---@field currencyGeneratorProgress number
---@field currencyGeneratorLastDirection integer
---@field miningProgress number
---@field miningOre integer
---@field miningOreInventory table<string, integer>
---@field miningDrillLevel integer
---@field mainGearTurnProgress number
---@field manualClickIncomeRemainder number
---@field lubricantTutorialCompleted boolean
---@field lubricantTutorialStep string
---@field tutorialVersion integer
---@field tutorialStep string
---@field tutorialCompleted boolean
---@type GearWorkshopGameData
local gameData_ = {
    geometryVersion = GearDefinitions.GeometryVersion,
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
    gearPurchaseCounts = {},
    permanentContentUnlocks = {},
    lubricantCooldownRemaining = 0,
    autoDriveUnlocked = false,
    gearWarehousePermanentlyUnlocked = false,
    upgradeRailPermanentlyUnlocked = false,
    autoDriveLevel = 0,
    globalIncomeLevel = 0,
    decayReductionLevel = 0,
    offlineIncomeLevel = 0,
    lastActiveTimestamp = 0,
    savedIncomePerSecond = 0,
    pendingOfflineCoins = 0,
    pendingOfflineSeconds = 0,
    idleAdDayKey = 0,
    idleAdWatchCount = 0,
    idleEligibleUntil = 0,
    currencyGeneratorProgress = 0,
    currencyGeneratorLastDirection = 0,
    miningProgress = 0,
    miningOre = 0,
    miningOreInventory = {
        iron = 0,
        copper = 0,
        silver = 0,
        gold = 0,
        crystal = 0,
    },
    miningDrillLevel = 1,
    mainGearTurnProgress = 0,
    manualClickIncomeRemainder = 0,
    tutorialVersion = 0,
    tutorialStep = TutorialRuntime.FirstStep,
    tutorialCompleted = false,
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
---@type boolean
responsiveLayout_.loadingActive = false
responsiveLayout_.loadingElapsed = 0
responsiveLayout_.loadingAssetIndex = 1
responsiveLayout_.loadingAssetRetries = 0
responsiveLayout_.loadingRendererInitialized = false
responsiveLayout_.loadingRoot = nil
responsiveLayout_.loadingStatusLabel = nil
responsiveLayout_.loadingPercentLabel = nil
responsiveLayout_.loadingProgressBar = nil
responsiveLayout_.loadingImagePaths = {
    "image/home_landscape_factory_blueprint_bg_20260818094330.png",
    "image/home_title_frame_wide_v3_trimmed.png",
    "image/home_factory_button_panel_final.png",
    "image/home_leaderboard_button_panel_final.png",
    "image/home_factory_entry_icon_20260818094329.png",
    "image/home_leaderboard_entry_icon_20260818094318.png",
    "image/home_leaderboard_frame_wide_v2_trimmed.png",
    "image/ui_coin_brass_comic_20260807004421.png",
    "image/ui_essence_core_comic_20260807004430.png",
    "image/ui_torque_bolt_comic_20260807004422.png",
    "image/gear_workshop_home_hud_icon_20260817122607.png",
    "image/hud_b_extracted/permanent.png",
    "image/locked_question_gear_comic_20260817094517.png",
    "image/hud_b_extracted/shaft.png",
    "image/hud_b_extracted/income.png",
    "image/hud_b_extracted/click.png",
    "image/hud_b_extracted/modify.png",
    "image/gear_main_comic_exact.png",
    "image/gear_small_comic_exact.png",
    "image/gear_medium_comic_exact.png",
    "image/gear_large_comic_exact.png",
    "image/gear_compound_comic_exact.png",
    "image/gear_momma_comic_exact.png",
    "image/gear_coin_large_comic_20260811093509.png",
    "image/ui_blueprint_clean/panel_left.png",
    "image/ui_blueprint_clean/panel_right.png",
    "image/ui_blueprint_clean/card_shop.png",
    "image/ui_blueprint_clean/card_upgrade.png",
    "image/ui_blueprint_clean/handle_left.png",
    "image/ui_blueprint_clean/handle_right.png",
    "image/ui_blueprint_clean/top_hud_frame.png",
}
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
local manualRotationActive_ = 0
---@type number
local mainGearPulse_ = 0
---@class IncomePopup
---@field x number
---@field y number
---@field radius number
---@field amount number
---@field amountText string|nil
---@field age number
---@field duration number
local incomeEffects_ = { popups = {} }
local connectedGearCount_ = 0
---@type number
local totalIncomePerSecond_ = 0
---@class GearNetworkState
---@field jammed boolean
---@field transmissionJammed boolean
---@field maintenanceJammed boolean
---@field lubricationActive boolean
---@field lubricationSourceGearId integer|nil
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
---@field externalNodes table<string, table>
---@field currencyGenerator table
---@field miningMachine table
---@field clockInterface table
---@field clockDisplay table
---@type GearNetworkState
local networkState_ = {
    jammed = false,
    transmissionJammed = false,
    maintenanceJammed = false,
    lubricationActive = false,
    lubricationSourceGearId = nil,
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
    externalNodes = {},
    currencyGenerator = {
        id = GearDefinitions.CurrencyGenerator.id,
        gearType = GearDefinitions.CurrencyGenerator.id,
        x = 0,
        y = 0,
        radius = 1,
        bodyX = 0,
        bodyY = 0,
        bodyWidth = 1,
        bodyHeight = 1,
        load = GearDefinitions.CurrencyGenerator.load,
        requiredTorque = GearDefinitions.CurrencyGenerator.requiredTorque,
        angle = 0,
        animationTime = 0,
        animationRunning = false,
        rewardFlash = 0,
        status = "unmeshed",
    },
    miningMachine = {
        id = GearDefinitions.MiningMachine.id,
        gearType = GearDefinitions.MiningMachine.id,
        x = 0,
        y = 0,
        radius = 1,
        bodyX = 0,
        bodyY = 0,
        bodyWidth = 1,
        bodyHeight = 1,
        load = 0,
        requiredTorque = 0,
        angle = 0,
        animationTime = 0,
        rewardFlash = 0,
        miningEfficiency = 0,
        status = "unmeshed",
    },
    powerGeneratorInterface = {
        id = GearDefinitions.PowerGeneratorInterface.id,
        gearType = GearDefinitions.PowerGeneratorInterface.id,
        x = 0,
        y = 0,
        radius = 1,
        bodyX = nil,
        bodyY = nil,
        bodyWidth = nil,
        bodyHeight = nil,
        load = GearDefinitions.PowerGeneratorInterface.load,
        requiredTorque = GearDefinitions.PowerGeneratorInterface.requiredTorque,
        angle = 0,
        status = "unmeshed",
    },
    powerGeneratorDisplay = {
        x = 0,
        y = 0,
        width = 1,
        height = 1,
        animationTime = 0,
        visible = true,
        alpha = 1,
    },
    clockInterface = {
        id = GearDefinitions.ClockInterface.id,
        gearType = GearDefinitions.ClockInterface.id,
        x = 0,
        y = 0,
        radius = 1,
        load = GearDefinitions.ClockInterface.load,
        requiredTorque = GearDefinitions.ClockInterface.requiredTorque,
        angle = 0,
        visible = true,
        status = "unmeshed",
    },
    clockDisplay = {
        x = 0,
        y = 0,
        width = 1,
        height = 1,
        animationTime = 0,
        running = false,
        visible = true,
        alpha = 1,
    },
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
local axleAssembly_ = {
    smallIndex = nil,
    largeIndex = nil,
}
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
---@field angle number
---@field snapped boolean
---@field snapAnchorIndex integer|string|nil
---@field axleTargetIndex integer|nil
---@field detailsPanel Widget|nil
---@field detailsTitle Label|nil
---@field detailsPrice Label|nil
---@field detailsDescription Label|nil
---@field generatorDetailsPanel Widget|nil
---@field generatorDetailsTitle Label|nil
---@field generatorDetailsStatus Label|nil
---@field generatorDetailsDescription Label|nil
---@field generatorDetailsPrimaryButton Button|nil
---@field generatorDetailsSecondaryButton Button|nil
---@field generatorDetailsActionDock Widget|nil
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
    angle = 0,
    snapped = false,
    snapAnchorIndex = nil,
    axleTargetIndex = nil,
    detailsPanel = nil,
    detailsTitle = nil,
    detailsPrice = nil,
    detailsDescription = nil,
    generatorDetailsPanel = nil,
    generatorDetailsTitle = nil,
    generatorDetailsStatus = nil,
    generatorDetailsDescription = nil,
    generatorDetailsPrimaryButton = nil,
    generatorDetailsSecondaryButton = nil,
    generatorDetailsActionDock = nil,
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
---@type fun(action: string, value: string|nil)|nil
local NotifyTutorial
---@type fun()|nil
local CreateLubricantTutorialController
---@type fun(smallIndex: integer, largeIndex: integer): boolean|nil
local AssembleLargeCompound

local function GetClickValue()
    return math.min(
        GearDefinitions.Main.manualClickMax,
        GearDefinitions.GetMainClickIncome(gameData_.clickLevel - 1)
            * GearDefinitions.GetGlobalIncomeMultiplier(
                gameData_.globalIncomeLevel
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
    local previousLifetimeCoins = gameData_.lifetimeCoinsEarned
    gameData_.coins = gameData_.coins + earned
    gameData_.runCoinsEarned = gameData_.runCoinsEarned + earned
    gameData_.lifetimeCoinsEarned =
        gameData_.lifetimeCoinsEarned + earned
    gameData_.metaRevision = gameData_.metaRevision + 1
    local unlockedMiningMachine = previousLifetimeCoins
            < GearDefinitions.MiningMachine.requiredLifetimeCoins
        and gameData_.lifetimeCoinsEarned
            >= GearDefinitions.MiningMachine.requiredLifetimeCoins
    local unlockedClock = previousLifetimeCoins
            < GearDefinitions.ClockInterface.requiredLifetimeCoins
        and gameData_.lifetimeCoinsEarned
            >= GearDefinitions.ClockInterface.requiredLifetimeCoins
    if (unlockedMiningMachine or unlockedClock) and RebuildGearNetwork then
        RebuildGearNetwork("累计资产解锁固定机器", true)
        print(string.format(
            "[Unlock] 累计资产达到￥%.0f: 矿机=%s, 钟表=%s",
            gameData_.lifetimeCoinsEarned,
            tostring(unlockedMiningMachine),
            tostring(unlockedClock)
        ))
    end
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

function GetConnectedSpecialIncomeBonus()
    local bonus = 0
    for gearIndex, gear in ipairs(gameData_.revenueGears) do
        if gear.connected then
            bonus = bonus
                + GearDefinitions.GetSpecialIncomeBonus(
                    gear.gearType,
                    gear.level
                ) * GetClockIncomeMultiplierForGearIndex(gearIndex)
        end
    end
    return bonus
end

function GetMainGearIncomeMultiplier()
    return 1 + GetConnectedSpecialIncomeBonus()
end

function GetClockBoostedGearIndex()
    local clockInterface = networkState_.clockInterface
    if not clockInterface
        or clockInterface.running ~= true
        or type(clockInterface.parentIndex) ~= "number" then
        return nil
    end
    return clockInterface.parentIndex
end

function GetClockIncomeMultiplierForGearIndex(gearIndex)
    return gearIndex == GetClockBoostedGearIndex()
        and GearDefinitions.ClockInterface.directIncomeMultiplier
        or 1
end

incomeEffects_.SpawnPopup = function(x, y, radius, amount, amountText)
    if amount <= 0 then
        return
    end
    incomeEffects_.popups[#incomeEffects_.popups + 1] = {
        x = x,
        y = y,
        radius = radius,
        amount = amount,
        amountText = amountText,
        age = 0,
        duration = 1.15,
    }
end

local function GetMainRPM()
    return math.min(
        GearDefinitions.Main.maxRPM,
        GearDefinitions.Main.baseRPM
    )
end

function GetMainIncomePerSecond()
    if not gameData_.autoDriveUnlocked then
        return 0
    end
    return GetMainCircleIncome()
        * GearDefinitions.GetGlobalIncomeMultiplier(
            gameData_.globalIncomeLevel
        )
        * GetMainGearIncomeMultiplier()
        * GetMainRPM()
        / 60
end

local function IsMainSpeedCapped()
    return gameData_.autoDriveUnlocked
        and GetMainRPM() >= GearDefinitions.Main.maxRPM
end

function FormatCompactMagnitude(value, divisor, suffix)
    local scaled = value / divisor
    local precision = scaled >= 100 and 0 or scaled >= 10 and 1 or 2
    local text = string.format("%." .. precision .. "f", scaled)
    text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
    return text .. suffix
end

local function FormatNumber(value)
    local safeValue = tonumber(value) or 0
    local absoluteValue = math.abs(safeValue)
    local sign = safeValue < 0 and "-" or ""
    if absoluteValue >= 1000000000000000 then
        return sign .. FormatCompactMagnitude(absoluteValue, 1000000000000000, "q")
    elseif absoluteValue >= 1000000000000 then
        return sign .. FormatCompactMagnitude(absoluteValue, 1000000000000, "t")
    elseif absoluteValue >= 1000000000 then
        return sign .. FormatCompactMagnitude(absoluteValue, 1000000000, "b")
    elseif absoluteValue >= 1000000 then
        return sign .. FormatCompactMagnitude(absoluteValue, 1000000, "m")
    elseif absoluteValue >= 1000 then
        return sign .. FormatCompactMagnitude(absoluteValue, 1000, "k")
    end

    if safeValue == math.floor(safeValue) then
        return tostring(math.floor(safeValue))
    end
    local text = string.format("%.2f", safeValue)
    return text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
end

function GetLeaderboardIncomeValue()
    local scaledIncome = (tonumber(totalIncomePerSecond_) or 0)
        * CONFIG.IncomeLeaderboardScale
    return math.max(0, math.floor(math.min(
        scaledIncome + 0.5,
        9000000000000000
    )))
end

function SetHomeLeaderboardStatus(text)
    local homeUI = responsiveLayout_.homeUI
    if homeUI and homeUI.setLeaderboardStatus then
        homeUI.setLeaderboardStatus(text)
    end
end

function ApplyHomeLeaderboard(entries)
    local homeUI = responsiveLayout_.homeUI
    if homeUI and homeUI.setLeaderboard then
        homeUI.setLeaderboard(entries)
    end
end

function RefreshHomeAssetDisplay()
    local homeUI = responsiveLayout_.homeUI
    if homeUI and homeUI.setAssetText then
        local assetText = "￥" .. FormatNumber(
            gameData_.lifetimeCoinsEarned
        )
        if assetText ~= responsiveLayout_.homeAssetText then
            responsiveLayout_.homeAssetText = assetText
            homeUI.setAssetText(assetText)
        end
    end
end

function ResolveLeaderboardNicknames(entries, userIds, requestId)
    if requestId ~= responsiveLayout_.homeLeaderboardRequestId then
        return
    end

    local getUserNickname = rawget(_G, "GetUserNickname")
    local function ApplyAnonymousNames()
        for _, entry in ipairs(entries) do
            entry.nickname = "匿名玩家"
        end
        responsiveLayout_.homeLeaderboardEntries = entries
        ApplyHomeLeaderboard(entries)
    end

    if type(getUserNickname) ~= "function" or #userIds == 0 then
        ApplyAnonymousNames()
        SetHomeLeaderboardStatus(string.format(
            "前%d名（昵称暂不可用）",
            #entries
        ))
        print("[Leaderboard] 当前环境没有可用的 GetUserNickname")
        return
    end

    local ok, callError = pcall(function()
        getUserNickname({
            userIds = userIds,
            onSuccess = function(nicknames)
                if requestId ~= responsiveLayout_.homeLeaderboardRequestId then
                    return
                end

                local nicknameByUserId = {}
                for _, info in ipairs(nicknames or {}) do
                    local nickname = type(info.nickname) == "string"
                            and info.nickname
                        or ""
                    if info.userId ~= nil and nickname ~= "" then
                        nicknameByUserId[tostring(info.userId)] = nickname
                    end
                end

                local resolvedCount = 0
                for _, entry in ipairs(entries) do
                    local nickname = nicknameByUserId[tostring(entry.userId)]
                    if nickname ~= nil then
                        entry.nickname = nickname
                        resolvedCount = resolvedCount + 1
                    else
                        entry.nickname = "匿名玩家"
                    end
                end

                responsiveLayout_.homeLeaderboardEntries = entries
                ApplyHomeLeaderboard(entries)
                SetHomeLeaderboardStatus(string.format(
                    "前%d名",
                    #entries
                ))
                print(string.format(
                    "[Leaderboard] 昵称查询完成: %d/%d",
                    resolvedCount,
                    #entries
                ))
            end,
            onError = function(errorCode)
                if requestId ~= responsiveLayout_.homeLeaderboardRequestId then
                    return
                end
                ApplyAnonymousNames()
                SetHomeLeaderboardStatus(string.format(
                    "前%d名（昵称暂不可用）",
                    #entries
                ))
                print(string.format(
                    "[Leaderboard] 昵称查询失败 code=%s",
                    tostring(errorCode)
                ))
            end,
        })
    end)

    if not ok then
        if requestId == responsiveLayout_.homeLeaderboardRequestId then
            ApplyAnonymousNames()
            SetHomeLeaderboardStatus(string.format(
                "前%d名（昵称暂不可用）",
                #entries
            ))
        end
        print(string.format(
            "[Leaderboard] GetUserNickname 调用失败: %s",
            tostring(callError)
        ))
    end
end

function LoadIncomeLeaderboard()
    if responsiveLayout_.homeLeaderboardLoading then
        return
    end
    if clientCloud == nil then
        SetHomeLeaderboardStatus("云端排行榜暂不可用")
        print("[Leaderboard] 当前环境无 clientCloud")
        return
    end

    responsiveLayout_.homeLeaderboardRequestId =
        responsiveLayout_.homeLeaderboardRequestId + 1
    local requestId = responsiveLayout_.homeLeaderboardRequestId
    responsiveLayout_.homeLeaderboardLoading = true
    SetHomeLeaderboardStatus("正在同步云端排行榜…")

    clientCloud:GetRankList(
        CONFIG.IncomeLeaderboardKey,
        0,
        CONFIG.IncomeLeaderboardLimit,
        {
            ok = function(rankList)
                if requestId ~= responsiveLayout_.homeLeaderboardRequestId then
                    print("[Leaderboard] 忽略过期排行榜结果")
                    return
                end

                local entries = {}
                local userIds = {}
                for index, item in ipairs(rankList or {}) do
                    local scoreTable = type(item.iscore) == "table"
                            and item.iscore
                        or {}
                    local score = tonumber(
                        scoreTable[CONFIG.IncomeLeaderboardKey]
                    ) or 0
                    local userId = item.userId or item.player
                    local nickname = "匿名玩家"
                    entries[#entries + 1] = {
                        rank = index,
                        userId = userId,
                        nickname = nickname,
                        incomeText = "￥" .. FormatNumber(
                            score / CONFIG.IncomeLeaderboardScale
                        ) .. "/秒",
                        isMe = userId ~= nil
                            and tostring(userId)
                                == tostring(clientCloud.userId),
                    }
                    if userId ~= nil then
                        userIds[#userIds + 1] = userId
                    end
                end

                responsiveLayout_.homeLeaderboardEntries = entries
                responsiveLayout_.homeLeaderboardLoading = false
                ApplyHomeLeaderboard(entries)
                SetHomeLeaderboardStatus(string.format(
                    "前%d名（昵称正在补全）",
                    #entries
                ))
                print(string.format(
                    "[Leaderboard] 已显示排行榜: %d 条，用户ID: %d 条",
                    #entries,
                    #userIds
                ))

                ResolveLeaderboardNicknames(entries, userIds, requestId)
            end,
            error = function(code, reason)
                if requestId ~= responsiveLayout_.homeLeaderboardRequestId then
                    return
                end
                responsiveLayout_.homeLeaderboardLoading = false
                if #responsiveLayout_.homeLeaderboardEntries > 0 then
                    ApplyHomeLeaderboard(
                        responsiveLayout_.homeLeaderboardEntries
                    )
                end
                SetHomeLeaderboardStatus("排行榜加载失败，请稍后再试")
                print(string.format(
                    "[Leaderboard] 读取失败 code=%s reason=%s",
                    tostring(code),
                    tostring(reason)
                ))
            end,
            timeout = function()
                if requestId ~= responsiveLayout_.homeLeaderboardRequestId then
                    return
                end
                responsiveLayout_.homeLeaderboardLoading = false
                if #responsiveLayout_.homeLeaderboardEntries > 0 then
                    ApplyHomeLeaderboard(
                        responsiveLayout_.homeLeaderboardEntries
                    )
                end
                SetHomeLeaderboardStatus("排行榜连接超时，请稍后再试")
                print("[Leaderboard] 读取云端排行榜超时")
            end,
        }
    )
end

function SyncIncomeLeaderboard(forceRefresh)
    if clientCloud == nil then
        if forceRefresh then
            LoadIncomeLeaderboard()
        end
        return
    end
    if responsiveLayout_.incomeLeaderboardWritePending then
        return
    end

    local incomeValue = GetLeaderboardIncomeValue()
    if not responsiveLayout_.incomeLeaderboardDirty
        and incomeValue == responsiveLayout_.lastIncomeLeaderboardValue then
        if forceRefresh then
            LoadIncomeLeaderboard()
        end
        return
    end

    responsiveLayout_.incomeLeaderboardWritePending = true
    clientCloud:SetInt(CONFIG.IncomeLeaderboardKey, incomeValue, {
        ok = function()
            responsiveLayout_.incomeLeaderboardWritePending = false
            responsiveLayout_.incomeLeaderboardDirty = false
            responsiveLayout_.lastIncomeLeaderboardValue = incomeValue
            print(string.format(
                "[Leaderboard] 每秒收益已同步: ￥%s/秒",
                FormatNumber(
                    incomeValue / CONFIG.IncomeLeaderboardScale
                )
            ))
            if forceRefresh or responsiveLayout_.homeVisible then
                LoadIncomeLeaderboard()
            end
        end,
        error = function(code, reason)
            responsiveLayout_.incomeLeaderboardWritePending = false
            responsiveLayout_.incomeLeaderboardDirty = true
            if forceRefresh then
                LoadIncomeLeaderboard()
            end
            print(string.format(
                "[Leaderboard] 每秒收益同步失败 code=%s reason=%s",
                tostring(code),
                tostring(reason)
            ))
        end,
        timeout = function()
            responsiveLayout_.incomeLeaderboardWritePending = false
            responsiveLayout_.incomeLeaderboardDirty = true
            if forceRefresh then
                LoadIncomeLeaderboard()
            end
            print("[Leaderboard] 每秒收益同步超时")
        end,
    })
end

function EnterGearFactory()
    if not responsiveLayout_.homeVisible then
        return
    end
    responsiveLayout_.homeVisible = false
    local homeUI = responsiveLayout_.homeUI
    if homeUI and homeUI.setVisible then
        homeUI.setVisible(false)
    end
    responsiveLayout_.mode = "landscape"
    graphics:SetOrientations("LandscapeLeft LandscapeRight")
    if responsiveLayout_.rebuild then
        responsiveLayout_.rebuild()
    end
    print("[Home] 已进入横屏齿轮工厂")
end

function ReturnToHome()
    if responsiveLayout_.homeVisible then
        return
    end
    if shopDrag_.gearType ~= nil then
        CancelShopGearDrag(shopDrag_.pointerId, shopDrag_.pointerType)
    end
    if activePointerId_ ~= nil and CancelCanvasPointer then
        CancelCanvasPointer(activePointerId_, activePointerType_)
    end
    ClearShopDragState()
    ClearPointerState()
    StopGearAudioPlayback("返回首页")
    responsiveLayout_.homeVisible = true
    responsiveLayout_.mode = "landscape"
    responsiveLayout_.homeLeaderboardLoading = false
    graphics:SetOrientations("LandscapeLeft LandscapeRight")
    if responsiveLayout_.rebuild then
        responsiveLayout_.rebuild()
    end
    RefreshHomeAssetDisplay()
    SyncIncomeLeaderboard(true)
    print("[Home] 已返回横屏首页")
end

function FormatCurrency(value)
    local safeValue = math.max(0, value or 0)
    if safeValue >= 1000 then
        return FormatNumber(safeValue)
    end
    return string.format("%.2f", safeValue)
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

function ScreenUIToLayoutUI(uiX, uiY)
    if responsiveLayout_.rotatePortrait then
        return responsiveLayout_.screenUIHeight - uiY, uiX
    end
    return uiX, uiY
end

local function PhysicalToLogical(physicalX, physicalY)
    local screenX = physicalX / dpr_
    local screenY = physicalY / dpr_
    if responsiveLayout_.rotatePortrait then
        return responsiveLayout_.screenLogicalHeight - screenY, screenX
    end
    return screenX, screenY
end

local function ScreenToWorld(screenX, screenY)
    return (screenX - canvasOffsetX_) / canvasScale_,
        (screenY - canvasOffsetY_) / canvasScale_
end

responsiveLayout_.RefreshFaultIndicator = function()
    local indicator = responsiveLayout_.faultIndicator
    local targetX
    local targetY
    local targetRadius = mainGearRadius_
    local reason
    local targetType
    local targetId

    for _, gear in ipairs(gameData_.revenueGears) do
        if gear.localJammed then
            targetX = gear.x
            targetY = gear.y
            targetRadius = gear.radius or revenueGearRadius_
            reason = gear.maintenanceJammed
                    and "齿轮缺油卡壳"
                or "齿轮啮合卡壳"
            targetType = "gear"
            targetId = gear.id
            break
        end
    end

    local currencyGenerator = networkState_.currencyGenerator
    if targetX == nil
        and currencyGenerator.status == "insufficientTorque" then
        targetX = currencyGenerator.bodyX or currencyGenerator.x
        targetY = currencyGenerator.bodyY or currencyGenerator.y
        targetRadius = math.max(
            currencyGenerator.radius or 0,
            (currencyGenerator.bodyWidth or 0) * 0.35
        )
        reason = "货币生成器扭矩不足"
        targetType = "currencyGenerator"
        targetId = currencyGenerator.id
    end

    local powerInterface = networkState_.powerGeneratorInterface
    if targetX == nil
        and powerInterface.status == "insufficientTorque" then
        targetX = powerInterface.x
        targetY = powerInterface.y
        targetRadius = powerInterface.radius or revenueGearRadius_
        reason = "发电机扭矩不足"
        targetType = "powerGenerator"
        targetId = powerInterface.id
    end

    if targetX == nil and networkState_.overloaded then
        targetX = mainGearX_
        targetY = mainGearY_
        reason = "主轴扭矩过载"
        targetType = "mainGear"
    elseif targetX == nil and networkState_.jammed then
        targetX = mainGearX_
        targetY = mainGearY_
        reason = "传动网络卡壳"
        targetType = "mainGear"
    end

    if targetX == nil then
        indicator.visible = false
        return indicator
    end

    local targetScreenX = targetX * canvasScale_ + canvasOffsetX_
    local targetScreenY = targetY * canvasScale_ + canvasOffsetY_
    local width = logicalWidth_
    local height = logicalHeight_
    local marginX = math.min(110, width * 0.12)
    local marginY = math.min(92, height * 0.15)
    local left = marginX
    local right = width - marginX
    local top = marginY
    local bottom = height - marginY
    local arrowX
    local arrowY

    if targetScreenX >= left and targetScreenX <= right
        and targetScreenY >= top and targetScreenY <= bottom then
        local standOff = targetRadius * canvasScale_ + 58
        arrowX = targetScreenX
        arrowY = targetScreenY - standOff
        if arrowY < top then
            arrowY = targetScreenY + standOff
        end
        arrowY = math.max(top, math.min(bottom, arrowY))
    else
        local centerX = width * 0.5
        local centerY = height * 0.5
        local dx = targetScreenX - centerX
        local dy = targetScreenY - centerY
        local edgeScale = 1
        if math.abs(dx) > 0.001 then
            edgeScale = math.min(
                edgeScale,
                (dx > 0 and right - centerX or centerX - left)
                    / math.abs(dx)
            )
        end
        if math.abs(dy) > 0.001 then
            edgeScale = math.min(
                edgeScale,
                (dy > 0 and bottom - centerY or centerY - top)
                    / math.abs(dy)
            )
        end
        arrowX = centerX + dx * edgeScale
        arrowY = centerY + dy * edgeScale
    end

    indicator.visible = true
    indicator.screenX = arrowX
    indicator.screenY = arrowY
    indicator.targetX = targetX
    indicator.targetY = targetY
    indicator.angle = math.atan(
        targetScreenY - arrowY,
        targetScreenX - arrowX
    )
    indicator.reason = reason
    indicator.targetType = targetType
    indicator.targetId = targetId
    return indicator
end

responsiveLayout_.IsFaultIndicatorAt = function(screenX, screenY)
    local indicator = responsiveLayout_.RefreshFaultIndicator()
    if not indicator.visible then
        return false
    end
    return DistanceSquared(
        screenX,
        screenY,
        indicator.screenX,
        indicator.screenY
    ) <= 46 * 46
end

responsiveLayout_.FocusFaultIndicator = function()
    local indicator = responsiveLayout_.RefreshFaultIndicator()
    if not indicator.visible then
        return false
    end
    canvasOffsetX_ = logicalWidth_ * 0.5
        - indicator.targetX * canvasScale_
    canvasOffsetY_ = logicalHeight_ * 0.5
        - indicator.targetY * canvasScale_
    responsiveLayout_.RefreshFaultIndicator()
    print(string.format(
        "[FaultIndicator] 自动定位: type=%s, id=%s, reason=%s, target=(%.1f, %.1f)",
        tostring(indicator.targetType),
        tostring(indicator.targetId),
        tostring(indicator.reason),
        indicator.targetX,
        indicator.targetY
    ))
    return true
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
        0.45,
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
    local width = math.max(
        1,
        responsiveLayout_.canvasRight - responsiveLayout_.canvasLeft
    )
    gear.xNorm = (gear.x - responsiveLayout_.canvasLeft) / width
    gear.yNorm = gear.y / logicalHeight_
    local radius = math.max(0.001, mainGearRadius_)
    gear.anchorX = (gear.x - mainGearX_) / radius
    gear.anchorY = (gear.y - mainGearY_) / radius
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

    local resetSnapshot = MetaProgression.CreateResetSnapshot()
    for _, legacyCloudKey in ipairs(MetaProgression.LegacyCloudKeys) do
        clientCloud:Set(legacyCloudKey, resetSnapshot, {
            ok = function()
                print("[MetaCloud] 旧版云端数据已清零: " .. legacyCloudKey)
            end,
            error = function(code, reason)
                print(string.format(
                    "[MetaCloud] 旧版云端数据清零失败 key=%s code=%s reason=%s",
                    legacyCloudKey,
                    tostring(code),
                    tostring(reason)
                ))
            end,
            timeout = function()
                print("[MetaCloud] 旧版云端数据清零超时: " .. legacyCloudKey)
            end,
        })
    end

    clientCloud:Get(MetaProgression.CloudKey, {
        ok = function(values)
            local cloudValue = type(values) == "table"
                and values[MetaProgression.CloudKey]
                or nil
            local cloudSnapshot = MetaProgression.NormalizeCloudSnapshot(
                cloudValue
            )
            if cloudSnapshot == nil then
                gameData_.metaRevision = math.max(
                    MetaProgression.ResetRevision,
                    gameData_.metaRevision
                )
                MarkSaveDirty(0)
                print("[MetaCloud] 新云端命名空间为空，准备写入全零基线")
            elseif MetaProgression.ShouldUseCloud(gameData_, cloudSnapshot) then
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

function GetIdleDayKey(now)
    return tonumber(os.date("%Y%m%d", now or os.time())) or 0
end

function GetIdleDayEndTimestamp(now)
    local current = now or os.time()
    local hour = tonumber(os.date("%H", current)) or 0
    local minute = tonumber(os.date("%M", current)) or 0
    local second = tonumber(os.date("%S", current)) or 0
    return current - hour * 3600 - minute * 60 - second + 86400
end

function RefreshIdleAdDay(now)
    local dayKey = GetIdleDayKey(now)
    if gameData_.idleAdDayKey ~= dayKey then
        gameData_.idleAdDayKey = dayKey
        gameData_.idleAdWatchCount = 0
        MarkSaveDirty(0)
        print(string.format(
            "[Idle] 每日广告进度已重置: day=%d",
            dayKey
        ))
    end
end

function IsIdleEarningsUnlocked(now)
    now = now or os.time()
    return gameData_.idleAdDayKey == GetIdleDayKey(now)
        and (gameData_.idleAdWatchCount or 0) >= 2
        and (gameData_.idleEligibleUntil or 0) > now
end

function GetIdleAdsRemaining(now)
    RefreshIdleAdDay(now or os.time())
    return math.max(0, 2 - (gameData_.idleAdWatchCount or 0))
end

local function SaveNow(reason)
    if not saveDirty_ then
        return
    end

    local now = os.time()
    gameData_.lastActiveTimestamp = now
    gameData_.savedIncomePerSecond =
        IsIdleEarningsUnlocked(now) and totalIncomePerSecond_ or 0
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

function HasActiveLubricantGear()
    for _, gear in ipairs(gameData_.revenueGears) do
        if gear.gearType == "lubricant"
            and (gear.lubricationRemaining or 0) > 0 then
            return true
        end
    end
    return false
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

function CloseTransientPopups(exceptPopup)
    if exceptPopup ~= "mainUpgrade"
        and responsiveLayout_.hideMainUpgradeDetails then
        responsiveLayout_.hideMainUpgradeDetails()
    end
    if exceptPopup ~= "gearDetails" then
        selectedGearIndex_ = nil
        if gearDetailsPanel_ then
            gearDetailsPanel_:SetVisible(false)
        end
    end
    if exceptPopup ~= "shopDetails" and shopDrag_.detailsPanel then
        shopDrag_.detailsPanel:SetVisible(false)
    end
    if exceptPopup ~= "generatorDetails"
        and shopDrag_.generatorDetailsPanel then
        shopDrag_.generatorDetailsPanel:SetVisible(false)
    end
    if exceptPopup ~= "globalUpgrade" and globalUpgradePanel_ then
        globalUpgradePanel_:SetVisible(false)
    end
    if exceptPopup ~= "ascension" and ascensionPanel_ then
        ascensionPanel_:SetVisible(false)
    end
end

function GetGearPurchaseCost(gearType)
    local counts = gameData_.gearPurchaseCounts or {}
    return GearDefinitions.GetPurchaseCost(
        gearType,
        counts[gearType] or 0
    )
end

function UnlockPermanentContent(key)
    gameData_.permanentContentUnlocks =
        gameData_.permanentContentUnlocks or {}
    if gameData_.permanentContentUnlocks[key] == true then
        return false
    end
    gameData_.permanentContentUnlocks[key] = true
    MarkSaveDirty(0)
    print("[Unlock] 内容已永久解锁: " .. key)
    return true
end

function IsShopGearRevealed(gearType)
    gameData_.permanentContentUnlocks =
        gameData_.permanentContentUnlocks or {}
    local unlockKey = "gear:" .. gearType
    if gameData_.permanentContentUnlocks[unlockKey] == true then
        return true
    end

    local definition = GearDefinitions.Get(gearType)
    local purchaseCount = (gameData_.gearPurchaseCounts or {})[gearType] or 0
    local reached = gameData_.lifetimeCoinsEarned >= definition.purchaseCost
        or gameData_.coins >= definition.purchaseCost
        or purchaseCount > 0
        or (gearType == "momma"
            and (
                gameData_.unlockedBuildings.precisionFoundry == true
                or gameData_.mommaFactoryStock > 0
            ))
    if reached then
        UnlockPermanentContent(unlockKey)
    end
    return reached
end

function IsUpgradeContentRevealed(upgradeType, currentLevel)
    gameData_.permanentContentUnlocks =
        gameData_.permanentContentUnlocks or {}
    local unlockKey = "upgrade:" .. upgradeType
    if gameData_.permanentContentUnlocks[unlockKey] == true then
        return true
    end

    local unlockCoins = GearDefinitions.UpgradeRevealCoins[upgradeType]
        or math.huge
    local reached = gameData_.coins >= unlockCoins
        or gameData_.lifetimeCoinsEarned >= unlockCoins
        or (currentLevel or 0) > 0
    if upgradeType == "permanent" then
        reached = reached
            or gameData_.gearEssence > 0
            or gameData_.globalIncomeLevel > 0
            or gameData_.decayReductionLevel > 0
            or gameData_.offlineIncomeLevel > 0
    end
    if reached then
        UnlockPermanentContent(unlockKey)
    end
    return reached
end

function ShowShopGearDetails(gearType)
    if not IsShopGearRevealed(gearType) then
        return
    end
    CloseTransientPopups("shopDetails")
    local definition = GearDefinitions.Get(gearType)
    local rings = GearDefinitions.GetRings(gearType)
    local teethText = string.format("齿数：%d", rings.outer.teeth)
    if rings.inner then
        teethText = string.format(
            "外层齿数：%d\n内层齿数：%d",
            rings.outer.teeth,
            rings.inner.teeth
        )
    end

    local specialtyText = "用于连接并延伸主齿轮传动链。"
    if gearType == "small" then
        specialtyText = "与主齿轮同为最小规格，尺寸和齿数完全一致；负载最低，适合延伸传动链。"
    elseif gearType == "medium" then
        specialtyText = "比最小规格大一级，承载与尺寸均衡，适合作为工坊的标准传动节点。"
    elseif gearType == "large" then
        specialtyText = "承载较高，适合重载传动；可与小型齿轮组装成巨型同轴复合齿轮。接入主轴网络后，升级可提高主齿轮收入。"
    elseif gearType == "compound" then
        specialtyText = "双层同轴结构，内外齿圈均可啮合，用于改变传动速度并扩展齿轮网络。"
    elseif gearType == "coin" then
        specialtyText = string.format(
            "大型特殊生产齿轮。接入动力后每完成完整一圈结算一次金币；基础每圈 ￥%s，当前全收益倍率后每圈 ￥%s。",
            FormatCurrency(definition.baseRewardPerTurn),
            FormatCurrency(
                definition.baseRewardPerTurn * GetGlobalIncomeMultiplier()
            )
        )
    elseif gearType == "momma" then
        specialtyText = "高扭矩、极低负载的高级双层齿轮，提供固定 x11.25 变速；接入主轴网络后，升级可提高主齿轮收入。"
    elseif gearType == "lubricant" then
        specialtyText = string.format(
            "自主动力的超小巡检齿轮，不参与啮合或负载；放置后自动驶向主齿轮和所有普通齿轮，并逐颗绕行润滑。Lv.1 有效期 %s，耗尽后自动消失并进入 %s 冷却；同一时间只能使用一枚。",
            FormatDuration(definition.lubricationDuration),
            FormatDuration(definition.cooldownSeconds)
        )
    end

    shopDrag_.detailsTitle:SetText(definition.name)
    shopDrag_.detailsPrice:SetText(string.format(
        "下次售价  ￥%s · 已购%s个",
        FormatNumber(GetGearPurchaseCost(gearType)),
        FormatNumber((gameData_.gearPurchaseCounts or {})[gearType] or 0)
    ))
    local upgradeEffectText = "升级后可提高转速和承载能力。"
    if gearType == "large" then
        upgradeEffectText = "升级作用（每级）：接入主轴网络时，主齿轮收入 +15%"
    elseif gearType == "large_compound" then
        upgradeEffectText = "固定变速倍率：x4.5\n升级作用（每级）：接入主轴网络时，主齿轮收入 +20%"
    elseif gearType == "momma" then
        upgradeEffectText = "固定变速倍率：x11.25\n升级作用（每级）：接入主轴网络时，主齿轮收入 +20%"
    elseif gearType == "compound" then
        upgradeEffectText = string.format(
            "固定变速倍率：x%s",
            FormatStat(GearDefinitions.GetFixedSpeedMultiplier(gearType, 1))
        )
    end
    local descriptionText
    if gearType == "lubricant" then
        descriptionText = string.format(
            "%s\n\n%s\n收益：不产生金币，仅用于润滑传动网络\n基础负载：%s\n承载容量：%s\n\n%s",
            specialtyText,
            teethText,
            FormatStat(definition.baseLoad),
            FormatStat(definition.baseTorque),
            "升级作用（每级）\n· 巡游、绕行和自转速度 +25%\n· 润滑油寿命 +10%"
        )
    elseif gearType == "coin" then
        descriptionText = string.format(
            "%s\n\n%s\n收益：每完整一圈结算 ￥%s\n基础负载：%s\n承载容量：%s\n\n升级后通过提高转速与承载能力增加平均产能。",
            specialtyText,
            teethText,
            FormatCurrency(
                definition.baseRewardPerTurn * GetGlobalIncomeMultiplier()
            ),
            FormatStat(definition.baseLoad),
            FormatStat(definition.baseTorque)
        )
    else
        descriptionText = string.format(
            "%s\n\n%s\n收益：不产生金币，仅传递主齿轮动力\n基础负载：%s\n承载容量：%s\n\n%s",
            specialtyText,
            teethText,
            FormatStat(definition.baseLoad),
            FormatStat(definition.baseTorque),
            upgradeEffectText
        )
    end
    shopDrag_.detailsDescription:SetText(descriptionText)
    shopDrag_.detailsPanel:SetVisible(true)
    print("[Shop] 查看商品详情: " .. gearType)
end

function ShowCurrencyGeneratorDetails()
    CloseTransientPopups("generatorDetails")
    NotifyTutorial("generator_details_opened")
    responsiveLayout_.selectedFixedMachine = "currencyGenerator"
    shopDrag_.generatorDetailsTitle:SetText("货币生成器")
    shopDrag_.generatorDetailsPrimaryButton:SetVisible(false)
    shopDrag_.generatorDetailsSecondaryButton:SetVisible(false)
    shopDrag_.generatorDetailsActionDock:SetVisible(false)
    local generator = networkState_.currencyGenerator
    local definition = GearDefinitions.CurrencyGenerator
    local statusText = generator.status == "running"
        and "运行中：正在按当前 RPM 累积整圈进度。"
        or generator.status == "insufficientTorque"
            and string.format(
                "扭矩不足：当前 %.2f / 需要 %.2f。",
                generator.torque or 0,
                definition.requiredTorque
            )
            or generator.status == "overloaded"
                and "网络超载：总负载超过主轴扭矩，生成器停机。"
                or generator.status == "jammed"
                    and "传动冲突：齿轮闭环方向矛盾，生成器停机。"
                    or generator.status == "sourceOff"
                        and string.format(
                            "动力未开启：主齿轮扭矩首次升级至 Lv.%d 后解锁自动运转。",
                            GearDefinitions.Main.autoUnlockTorqueLevel
                        )
                        or generator.status == "isolated"
                            and "已与齿轮咬合，但尚未形成连接主轴的完整传动链。"
                            or "尚未连接：将传动齿轮同时连接主轴传动链与生成器外露齿圈。"
    local rewardPerTurn = math.floor(
        math.max(0, totalIncomePerSecond_)
            * definition.rewardProductionSeconds
    )

    local generatorStateLabel = generator.status == "running"
            and "ONLINE  /  正在生产"
        or generator.status == "insufficientTorque"
            and "LOW TORQUE  /  扭矩不足"
        or generator.status == "jammed"
            and "JAMMED  /  传动卡死"
        or generator.status == "overloaded"
            and "OVERLOAD  /  网络过载"
        or "STANDBY  /  等待接入"
    local generatorStatusColor = generator.status == "running"
            and { 92, 238, 154, 255 }
        or (generator.status == "jammed"
                or generator.status == "overloaded")
            and { 255, 93, 82, 255 }
        or generator.status == "insufficientTorque"
            and { 255, 198, 64, 255 }
        or { 111, 231, 255, 255 }
    shopDrag_.generatorDetailsStatus:SetStyle({
        fontColor = generatorStatusColor,
    })
    shopDrag_.generatorDetailsStatus:SetText(string.format(
        "%s  ·  %.2f RPM  ·  扭矩 %.2f / %.2f",
        generatorStateLabel,
        generator.rpm or 0,
        generator.torque or 0,
        definition.requiredTorque
    ))
    shopDrag_.generatorDetailsDescription:SetText(string.format(
        "核心数据\n单圈预计收益    ￥%s\n当前圈进度      %.0f%%\n生产周期系数    %d 秒\n\n接入规格\n接口齿数        %d 齿\n启动扭矩        %.2f\n固定负载        %.2f\n\n运行方式\n将主轴传动链连接到机器下方外露齿轮。成功接入后，机器按传入 RPM 累积圈数；每完成一圈立即结算。转速越高，结算越快。\n\n运行诊断\n%s",
        FormatNumber(rewardPerTurn),
        gameData_.currencyGeneratorProgress * 100,
        definition.rewardProductionSeconds,
        definition.rings.outer.teeth,
        definition.requiredTorque,
        definition.load,
        statusText
    ))
    shopDrag_.generatorDetailsPanel:SetVisible(true)
    print(string.format(
        "[CurrencyGenerator] 打开功能说明: status=%s, rpm=%.2f, torque=%.2f, progress=%.2f",
        tostring(generator.status),
        generator.rpm or 0,
        generator.torque or 0,
        gameData_.currencyGeneratorProgress
    ))
end

function ShowClockDetails()
    CloseTransientPopups("generatorDetails")
    responsiveLayout_.selectedFixedMachine = "clock"
    shopDrag_.generatorDetailsTitle:SetText("增益钟表")
    shopDrag_.generatorDetailsPrimaryButton:SetVisible(false)
    shopDrag_.generatorDetailsSecondaryButton:SetVisible(false)
    shopDrag_.generatorDetailsActionDock:SetVisible(false)
    local clockInterface = networkState_.clockInterface
    local boostedIndex = GetClockBoostedGearIndex()
    local boostedGear = boostedIndex
        and gameData_.revenueGears[boostedIndex]
        or nil
    local clockAssetUnlocked = gameData_.lifetimeCoinsEarned
        >= GearDefinitions.ClockInterface.requiredLifetimeCoins
    local stateLabel = not clockAssetUnlocked
            and "LOCKED  /  资产未达标"
        or clockInterface.running == true
            and "ONLINE  /  增益运行中"
        or clockInterface.status == "insufficientTorque"
            and "LOW TORQUE  /  扭矩不足"
        or clockInterface.meshed == true
            and "STANDBY  /  等待动力"
        or "OFFLINE  /  尚未连接"
    local stateColor = not clockAssetUnlocked
            and { 255, 93, 82, 255 }
        or clockInterface.running == true
            and { 92, 238, 154, 255 }
        or { 255, 198, 64, 255 }
    local targetText = boostedGear
            and string.format(
                "%s #%d",
                GearDefinitions.Get(boostedGear.gearType).name,
                boostedGear.id
            )
        or "无"
    shopDrag_.generatorDetailsStatus:SetStyle({ fontColor = stateColor })
    shopDrag_.generatorDetailsStatus:SetText(string.format(
        "%s  ·  %.2f RPM  ·  扭矩 %.2f / %.2f  ·  直连目标：%s",
        stateLabel,
        clockInterface.rpm or 0,
        clockInterface.torque or 0,
        GearDefinitions.ClockInterface.requiredTorque,
        targetText
    ))
    shopDrag_.generatorDetailsDescription:SetText(string.format(
        "核心效果\n与钟表接口直接咬合的玩家齿轮，其收益效果提高 20%%。\n\n解锁条件\n累计资产        ￥%s / ￥%s\n启动扭矩        %.2f\n\n当前直连齿轮    %s\n当前收益倍率    x%.2f\n接口齿数        %d 齿\n固定负载        %.2f\n\n生效范围\n大型金币齿轮：每完整一圈的金币奖励提高 20%%。\n大型、巨型或母齿轮：它们提供的主齿轮收入加成提高 20%%。\n普通传动齿轮不直接产币，因此只负责启动钟表，不会凭空产生收益。\n\n启动方式\n累计资产达到 ￥%s 后解除黑色遮罩；再用传动链将主齿轮动力接到钟表左下方黄铜接口齿轮。接口必须获得至少 %.0f 扭矩，钟表动画和接口齿轮才会转动，20%%增益才会生效。",
        FormatNumber(gameData_.lifetimeCoinsEarned),
        FormatNumber(GearDefinitions.ClockInterface.requiredLifetimeCoins),
        GearDefinitions.ClockInterface.requiredTorque,
        targetText,
        boostedGear
                and GearDefinitions.ClockInterface.directIncomeMultiplier
            or 1,
        GearDefinitions.ClockInterface.rings.outer.teeth,
        GearDefinitions.ClockInterface.load,
        FormatNumber(GearDefinitions.ClockInterface.requiredLifetimeCoins),
        GearDefinitions.ClockInterface.requiredTorque
    ))
    shopDrag_.generatorDetailsPanel:SetVisible(true)
    print(string.format(
        "[Clock] 打开功能说明: running=%s, target=%s, rpm=%.2f",
        tostring(clockInterface.running == true),
        targetText,
        clockInterface.rpm or 0
    ))
end

responsiveLayout_.NormalizeMiningInventory = function()
    local definition = GearDefinitions.MiningMachine
    local inventory = gameData_.miningOreInventory
    if type(inventory) ~= "table" then
        inventory = {}
        gameData_.miningOreInventory = inventory
    end
    local remainingCapacity = definition.maxOre
    for _, oreId in ipairs(definition.oreTypeOrder) do
        local amount = math.max(
            0,
            math.floor(tonumber(inventory[oreId]) or 0)
        )
        amount = math.min(remainingCapacity, amount)
        inventory[oreId] = amount
        remainingCapacity = remainingCapacity - amount
    end
    gameData_.miningOre = definition.maxOre - remainingCapacity
    return gameData_.miningOre
end

responsiveLayout_.GetMiningSaleValue = function()
    local definition = GearDefinitions.MiningMachine
    local inventory = gameData_.miningOreInventory or {}
    local value = 0
    for _, oreId in ipairs(definition.oreTypeOrder) do
        local ore = definition.oreTypes[oreId]
        value = value + (inventory[oreId] or 0) * ore.sellCoins
    end
    return value
end

responsiveLayout_.RollMiningOreType = function()
    local definition = GearDefinitions.MiningMachine
    local totalWeight = 0
    for _, oreId in ipairs(definition.oreTypeOrder) do
        totalWeight = totalWeight + definition.oreTypes[oreId].weight
    end
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, oreId in ipairs(definition.oreTypeOrder) do
        cumulative = cumulative + definition.oreTypes[oreId].weight
        if roll <= cumulative then
            return oreId
        end
    end
    return definition.oreTypeOrder[1]
end

responsiveLayout_.AddRandomMiningOre = function(amount)
    local inventory = gameData_.miningOreInventory
    for _ = 1, math.max(0, math.floor(amount or 0)) do
        local oreId = responsiveLayout_.RollMiningOreType()
        inventory[oreId] = (inventory[oreId] or 0) + 1
    end
    return responsiveLayout_.NormalizeMiningInventory()
end

responsiveLayout_.ConsumeMiningOre = function(amount)
    local inventory = gameData_.miningOreInventory or {}
    local remaining = math.max(0, math.floor(amount or 0))
    if responsiveLayout_.NormalizeMiningInventory() < remaining then
        return false
    end
    for _, oreId in ipairs(GearDefinitions.MiningMachine.oreTypeOrder) do
        local consumed = math.min(inventory[oreId] or 0, remaining)
        inventory[oreId] = (inventory[oreId] or 0) - consumed
        remaining = remaining - consumed
        if remaining <= 0 then
            break
        end
    end
    responsiveLayout_.NormalizeMiningInventory()
    return true
end

responsiveLayout_.BuildMiningInventoryText = function()
    local definition = GearDefinitions.MiningMachine
    local inventory = gameData_.miningOreInventory or {}
    local lines = {}
    for _, oreId in ipairs(definition.oreTypeOrder) do
        local ore = definition.oreTypes[oreId]
        local amount = inventory[oreId] or 0
        lines[#lines + 1] = string.format(
            "%s（%s · %.0f%%）：%s 个 × ￥%s = ￥%s",
            ore.name,
            ore.rarity,
            ore.weight,
            FormatNumber(amount),
            FormatNumber(ore.sellCoins),
            FormatNumber(amount * ore.sellCoins)
        )
    end
    return table.concat(lines, "\n")
end

function GetMiningEfficiency(machine)
    local definition = GearDefinitions.MiningMachine
    if not machine.powered
        or not machine.electricPowered
        or (machine.rpm or 0) < definition.minRPM
        or (machine.rpm or 0) > definition.maxRPM
        or responsiveLayout_.NormalizeMiningInventory()
            >= definition.maxOre then
        return 0
    end

    local rpm = machine.rpm or 0
    local rpmEfficiency = 1
    if rpm < definition.idealMinRPM then
        rpmEfficiency = 0.55
            + (rpm - definition.minRPM)
                / (definition.idealMinRPM - definition.minRPM)
                * 0.45
    elseif rpm > definition.idealMaxRPM then
        rpmEfficiency = 1
            - (rpm - definition.idealMaxRPM)
                / (definition.maxRPM - definition.idealMaxRPM)
                * 0.60
    end
    local torqueEfficiency = math.max(
        0,
        math.min(1, (machine.torque or 0) / definition.idealTorque)
    )
    return math.max(0, math.min(1, rpmEfficiency * torqueEfficiency))
end

function ShowMiningMachineDetails()
    CloseTransientPopups("generatorDetails")
    responsiveLayout_.selectedFixedMachine = "miningMachine"
    local machine = networkState_.miningMachine
    local generator = networkState_.powerGeneratorInterface
    local definition = GearDefinitions.MiningMachine
    local drill = definition.drillLevels[gameData_.miningDrillLevel]
    local oreTotal = responsiveLayout_.NormalizeMiningInventory()
    local saleValue = responsiveLayout_.GetMiningSaleValue()
    local inventoryText = responsiveLayout_.BuildMiningInventoryText()
    local efficiency = GetMiningEfficiency(machine)
    local assetUnlocked = gameData_.lifetimeCoinsEarned
        >= definition.requiredLifetimeCoins
    local statusText
    if not assetUnlocked then
        statusText = string.format(
            "资产未达标：累计资产 ￥%s / 需要 ￥%s。",
            FormatNumber(gameData_.lifetimeCoinsEarned),
            FormatNumber(definition.requiredLifetimeCoins)
        )
    elseif oreTotal >= definition.maxOre then
        statusText = "矿仓已满：交付矿石后继续开采。"
    elseif not machine.electricPowered then
        if generator.mechanicallyRotating then
            statusText = "发电机正在启动，等待电力状态同步。"
        elseif generator.status == "jammed" then
            statusText = "发电机传动卡死：点击红色故障箭头定位卡壳齿轮。"
        elseif generator.status == "overloaded" then
            statusText = "发电机网络过载：提升主轴扭矩或降低负载。"
        elseif generator.connected then
            statusText = "发电机已连接但主轴未自动运转。"
        else
            statusText = "等待供电：用齿轮链连接主轴与发电机接口。"
        end
    elseif machine.status == "insufficientTorque" then
        statusText = string.format(
            "扭矩不足：当前 %.2f / 需要 %.2f。",
            machine.torque or 0,
            definition.requiredTorque
        )
    elseif machine.status == "insufficientRPM" then
        statusText = string.format(
            "转速不足：当前 %.2f RPM / 启动需要 %.0f RPM。请使用大齿轮驱动小齿轮进行提速。",
            machine.rpm or 0,
            definition.minRPM
        )
    elseif machine.status == "overspeed" then
        statusText = string.format(
            "钻速过高：当前 %.2f RPM / 上限 %.0f RPM。",
            machine.rpm or 0,
            definition.maxRPM
        )
    elseif machine.status == "overloaded" then
        statusText = "网络超载：总负载超过主轴扭矩，矿机停机。"
    elseif machine.status == "jammed" then
        statusText = "传动卡死：检查闭环冲突与齿轮润滑。"
    elseif machine.status == "sourceOff" then
        statusText = "动力未开启：升级主轴扭矩以解锁自动运转。"
    elseif machine.status == "isolated" then
        statusText = "已与齿轮咬合，但尚未形成连接主轴的传动链。"
    elseif machine.status == "running" then
        statusText = "开采中：稳定转速与高扭矩会提高钻进效率。"
    else
        statusText = "尚未连接：用齿轮连接主轴传动链与矿机接口。"
    end

    local machineStateLabel = not assetUnlocked
            and "LOCKED  /  资产未达标"
        or machine.status == "running"
            and "ONLINE  /  正在开采"
        or machine.status == "insufficientRPM"
            and "LOW RPM  /  转速不足"
        or machine.status == "overspeed"
            and "OVERSPEED  /  转速过高"
        or machine.status == "insufficientTorque"
            and "LOW TORQUE  /  扭矩不足"
        or machine.status == "jammed"
            and "JAMMED  /  传动卡死"
        or machine.status == "overloaded"
            and "OVERLOAD  /  网络过载"
        or oreTotal >= definition.maxOre
            and "STORAGE FULL  /  矿仓已满"
        or "STANDBY  /  等待供电"
    local machineStatusColor = not assetUnlocked
            and { 255, 93, 82, 255 }
        or machine.status == "running"
            and { 92, 238, 154, 255 }
        or (machine.status == "jammed"
                or machine.status == "overloaded")
            and { 255, 93, 82, 255 }
        or (machine.status == "insufficientTorque"
                or machine.status == "insufficientRPM"
                or machine.status == "overspeed"
                or oreTotal >= definition.maxOre)
            and { 255, 198, 64, 255 }
        or { 111, 231, 255, 255 }
    shopDrag_.generatorDetailsTitle:SetText(definition.name)
    shopDrag_.generatorDetailsStatus:SetStyle({
        fontColor = machineStatusColor,
    })
    shopDrag_.generatorDetailsStatus:SetText(string.format(
        "%s  ·  矿仓 %d/%d  ·  效率 %.0f%%",
        machineStateLabel,
        oreTotal,
        definition.maxOre,
        efficiency * 100
    ))
    shopDrag_.generatorDetailsDescription:SetText(string.format(
        "生产概览\n累计资产        ￥%s / ￥%s\n钻头等级        Lv.%d\n钻进进度        %.0f%%\n单轮产量        %d 个矿石\n单轮耗时        %.0f 秒\n库存出售价值    ￥%s\n\n矿仓明细\n%s\n\n动力规格\n发电机输入      %.2f RPM  /  %.2f 扭矩\n矿机钻速        %.2f RPM\n启动转速        %.0f RPM\n最佳钻速        %.0f–%.0f RPM\n最高安全转速    %.0f RPM\n启动扭矩        %.2f\n理想扭矩        %.2f\n固定负载        %.2f\n\n解锁方式\n累计资产达到 ￥%s 后解除黑色遮罩；机器仍需至少 %.0f 扭矩与 26 RPM 才能启动。\n\n提速提示\n大齿轮驱动小齿轮会提高转速；小齿轮驱动大齿轮会降低转速并提高扭矩。\n\n操作说明\n出售会一次性清空矿仓并获得上方总价值。强化钻头需要金币与矿石，系统优先消耗低价值矿石。\n\n运行诊断\n%s",
        FormatNumber(gameData_.lifetimeCoinsEarned),
        FormatNumber(definition.requiredLifetimeCoins),
        gameData_.miningDrillLevel,
        gameData_.miningProgress * 100,
        drill.orePerCycle,
        drill.cycleSeconds,
        FormatNumber(saleValue),
        inventoryText,
        machine.generatorRPM or 0,
        machine.generatorTorque or 0,
        machine.rpm or 0,
        definition.minRPM,
        definition.idealMinRPM,
        definition.idealMaxRPM,
        definition.maxRPM,
        definition.requiredTorque,
        definition.idealTorque,
        definition.load,
        FormatNumber(definition.requiredLifetimeCoins),
        definition.requiredTorque,
        statusText
    ))
    shopDrag_.generatorDetailsPrimaryButton:SetText(string.format(
        "出售全部 %s 个矿石  +￥%s",
        FormatNumber(oreTotal),
        FormatNumber(saleValue)
    ))
    shopDrag_.generatorDetailsPrimaryButton:SetDisabled(
        not assetUnlocked or oreTotal <= 0
    )
    shopDrag_.generatorDetailsPrimaryButton:SetVisible(true)

    local nextDrill = definition.drillLevels[gameData_.miningDrillLevel + 1]
    if nextDrill then
        shopDrag_.generatorDetailsSecondaryButton:SetText(string.format(
            "强化钻头  ￥%s + 任意%s矿石",
            FormatNumber(nextDrill.coinCost),
            FormatNumber(nextDrill.oreCost)
        ))
        shopDrag_.generatorDetailsSecondaryButton:SetDisabled(
            not assetUnlocked
                or gameData_.coins < nextDrill.coinCost
                or oreTotal < nextDrill.oreCost
        )
    else
        shopDrag_.generatorDetailsSecondaryButton:SetText("钻头已满级")
        shopDrag_.generatorDetailsSecondaryButton:SetDisabled(true)
    end
    shopDrag_.generatorDetailsSecondaryButton:SetVisible(true)
    shopDrag_.generatorDetailsActionDock:SetVisible(true)
    shopDrag_.generatorDetailsPanel:SetVisible(true)
end

function DeliverMiningOre()
    if gameData_.lifetimeCoinsEarned
        < GearDefinitions.MiningMachine.requiredLifetimeCoins then
        return
    end
    local oreTotal = responsiveLayout_.NormalizeMiningInventory()
    local saleValue = responsiveLayout_.GetMiningSaleValue()
    if oreTotal <= 0 or saleValue <= 0 then
        return
    end
    for _, oreId in ipairs(GearDefinitions.MiningMachine.oreTypeOrder) do
        gameData_.miningOreInventory[oreId] = 0
    end
    responsiveLayout_.NormalizeMiningInventory()
    local reward = CreditCoins(saleValue)
    incomeEffects_.SpawnPopup(
        networkState_.miningMachine.x,
        networkState_.miningMachine.y,
        networkState_.miningMachine.radius,
        reward
    )
    networkState_.miningMachine.rewardFlash = 1
    RefreshUI()
    ShowMiningMachineDetails()
    MarkSaveDirty(0)
    print(string.format(
        "[MiningMachine] 出售全部%d个矿石，获得￥%d，库存清空",
        oreTotal,
        reward
    ))
end

function UpgradeMiningDrill()
    if gameData_.lifetimeCoinsEarned
        < GearDefinitions.MiningMachine.requiredLifetimeCoins then
        return
    end
    local definition = GearDefinitions.MiningMachine
    local nextLevel = gameData_.miningDrillLevel + 1
    local nextDrill = definition.drillLevels[nextLevel]
    if not nextDrill
        or gameData_.coins < nextDrill.coinCost
        or responsiveLayout_.NormalizeMiningInventory()
            < nextDrill.oreCost then
        return
    end
    gameData_.coins = gameData_.coins - nextDrill.coinCost
    if not responsiveLayout_.ConsumeMiningOre(nextDrill.oreCost) then
        gameData_.coins = gameData_.coins + nextDrill.coinCost
        return
    end
    gameData_.miningDrillLevel = nextLevel
    RefreshUI()
    ShowMiningMachineDetails()
    MarkSaveDirty(0)
    print(string.format(
        "[MiningMachine] 钻头升级至Lv.%d，消耗￥%d和%d矿石",
        nextLevel,
        nextDrill.coinCost,
        nextDrill.oreCost
    ))
end

local function RefreshSelectedGearUI()
    if gearDetailsPanel_ == nil then
        return
    end

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

    CloseTransientPopups("gearDetails")
    local definition = GearDefinitions.Get(gear.gearType)
    local status = "未连接动力"
    if gear.gearType == "lubricant"
        and (gear.lubricationRemaining or 0) <= 0 then
        status = "润滑剂已耗尽 · 巡游停止"
    elseif gear.maintenanceJammed then
        status = "润滑耗尽，齿轮已卡壳 · 接入润滑齿轮恢复"
    elseif gear.jammed then
        status = networkState_.maintenanceJammed
            and "网络中存在缺油齿轮，传动已停机"
            or "传动闭环冲突，齿轮已卡死"
    elseif gear.overloaded then
        status = "总负载超过总扭矩，齿轮已锁死"
    elseif gear.connected then
        if gear.gearType == "lubricant" then
            status = "自主巡游中 · 不依赖主轴或其他齿轮驱动"
        else
            local inputRingName = gear.inputRing == "inner"
                and "内层小齿圈"
                or "外层齿圈"
            status = string.format(
                "动力已连接 · 第 %d 级传动 · 输入：%s",
                gear.transmissionDepth,
                inputRingName
            )
        end
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
    local clockBoosted = selectedGearIndex_ == GetClockBoostedGearIndex()
    local clockMultiplier = clockBoosted
            and GearDefinitions.ClockInterface.directIncomeMultiplier
        or 1
    local incomeText = "收益  不产生金币 · 仅负责传动"
    if gear.gearType == "coin" then
        local rewardPerTurn = definition.baseRewardPerTurn
            * GetGlobalIncomeMultiplier()
            * clockMultiplier
        incomeText = string.format(
            "收益  ￥%s/完整圈 · 圈进度 %.0f%% · 平均 ￥%s/秒%s",
            FormatCurrency(rewardPerTurn),
            (gear.turnProgress or 0) * 100,
            FormatCurrency(
                gear.connected and rewardPerTurn * gear.rpm / 60 or 0
            ),
            clockBoosted and " · 钟表直连 x1.20" or ""
        )
    elseif (definition.incomeBonusPerLevel or 0) > 0 then
        incomeText = string.format(
            "收益辅助  主齿轮收入 +%.0f%% · %s%s",
            GearDefinitions.GetSpecialIncomeBonus(
                gear.gearType,
                gear.level
            ) * clockMultiplier * 100,
            gear.connected and "已接入生效" or "等待接入主轴网络",
            clockBoosted and " · 钟表直连 x1.20" or ""
        )
    elseif clockBoosted then
        incomeText = "收益  本齿轮不直接产币 · 已启动钟表，收益增益无可作用项目"
    end
    gearDetailsStatsLabel_:SetText(string.format(
        "%s\n层级  %d · 齿轮负载  %s\n层负载  %s · 压速系数 x%s\n整体轴转速  %s RPM%s\n轴上传入扭矩  %s\n%s",
        teethText,
        gear.transmissionDepth,
        FormatStat(gear.load),
        FormatStat(layerLoad),
        FormatStat(layerSpeedFactor),
        FormatStat(gear.rpm),
        gear.speedCapped and " · 触顶锁速" or "",
        FormatStat(gear.torque),
        incomeText
    ))
    local specialtyText = ""
    if gear.gearType == "momma" then
        specialtyText = string.format(
            "\n母齿轮专属：固定变速 x11.25 · 极低负载 %.2f\n高扭矩承载 %.0f",
            definition.baseLoad,
            definition.baseTorque
        )
    elseif gear.gearType == "coin" then
        specialtyText = string.format(
            "\n金币齿轮专属：大型 32 齿生产结构\n只在动力接通并完成完整一圈后结算金币"
        )
    elseif gear.gearType == "large_compound" then
        specialtyText = string.format(
            "\n同轴结构：大型外圈 %d 齿 + 小型内圈 %d 齿\n整根轴共享 RPM · 内外齿圈均可继续啮合",
            rings.outer.teeth,
            rings.inner.teeth
        )
    elseif gear.gearType == "large" then
        specialtyText = "\n装配提示：将小型与大型齿轮的轴心重合，可组合为大型同轴复合齿轮"
    elseif gear.gearType == "lubricant" then
        specialtyText = string.format(
            "\n自主巡游：剩余 %s · 当前访问第 %d 个目标\n不靠其他齿轮驱动 · 自动沿所有齿轮逐颗绕行",
            FormatDuration(gear.lubricationRemaining or 0),
            gear.patrolTargetCursor or 1
        )
    else
        specialtyText = string.format(
            "\n润滑寿命：%s%s",
            FormatDuration(gear.lubricationRemaining or 0),
            gear.lubricated and " · 网络润滑中" or ""
        )
    end
    local upgradeSummary
    if gear.gearType == "lubricant" then
        upgradeSummary = string.format(
            "Lv.%d · 巡游速度 x%s\n润滑油总寿命 %s · 剩余 %s\n每级作用：加速 +%.0f%% · 润滑油寿命 +%.0f%%",
            gear.level,
            FormatStat(GearDefinitions.GetLubricantSpeedMultiplier(
                gear.level
            )),
            FormatDuration(GearDefinitions.GetLubricationDuration(
                gear.level
            )),
            FormatDuration(gear.lubricationRemaining or 0),
            definition.speedBonusPerLevel * 100,
            definition.lifetimeBonusPerLevel * 100
        )
    elseif (definition.incomeBonusPerLevel or 0) > 0 then
        local currentIncomeBonus = GearDefinitions.GetSpecialIncomeBonus(
            gear.gearType,
            gear.level
        )
        upgradeSummary = string.format(
            "Lv.%d · 当前主齿轮收入 +%.0f%%\n每级作用：主齿轮收入 +%.0f%%\n仅接入主轴网络时生效 · 当前%s",
            gear.level,
            currentIncomeBonus * 100,
            definition.incomeBonusPerLevel * 100,
            gear.connected and "已生效" or "未生效"
        )
    else
        upgradeSummary = string.format(
            "Lv.%d · 转速 x%s\n承载 %s · 固定 x%s",
            gear.level,
            FormatStat(GearDefinitions.GetSpeedMultiplier(gear.level)),
            FormatStat(GearDefinitions.GetTorqueCapacity(
                gear.gearType,
                gear.level
            )),
            FormatStat(GearDefinitions.GetFixedSpeedMultiplier(
                gear.gearType,
                gear.transmissionDepth
            ))
        )
    end
    gearDetailsUpgradeLabel_:SetText(upgradeSummary .. specialtyText)
    gearDetailsEssenceLabel_:SetText(string.format(
        "永久精华 %s · 飞升 %d 次\n全收益 x%s",
        FormatNumber(gameData_.gearEssence),
        gameData_.ascensionCount,
        FormatStat(GetGlobalIncomeMultiplier())
    ))
    gearUpgradeButton_:SetText(
        "升级此齿轮  ￥" .. FormatNumber(upgradeCost)
    )
    gearUpgradeButton_:SetDisabled(gameData_.coins < upgradeCost)
    if responsiveLayout_.gearDeleteButton then
        responsiveLayout_.gearDeleteButton:SetText(
            "删除并回收  +￥" .. FormatNumber(GetGearRecycleRefund(gear))
        )
    end
    gearDetailsPanel_:SetVisible(true)
end

local function RefreshRevenueUI()
    if revenueLabel_ == nil then
        return
    end

    revenueLabel_:SetText(string.format(
        "全网平均产能  ￥%s/秒",
        FormatCurrency(totalIncomePerSecond_)
    ))

    local powerState = "待解锁自动运转"
    if networkState_.maintenanceJammed then
        powerState = "润滑耗尽 · 放置润滑齿轮恢复"
    elseif networkState_.transmissionJammed then
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

    local generator = networkState_.currencyGenerator
    local generatorStatus = generator.status == "running"
        and string.format(
            "货币钟 %.2f RPM · 扭矩 %.2f/%.2f\n圈进度 %.0f%%",
            generator.rpm,
            generator.torque,
            GearDefinitions.CurrencyGenerator.requiredTorque,
            gameData_.currencyGeneratorProgress * 100
        )
        or generator.status == "insufficientTorque"
            and string.format(
                "货币钟扭矩不足 %.2f/%.2f",
                generator.torque,
                GearDefinitions.CurrencyGenerator.requiredTorque
            )
            or generator.status == "overloaded"
                and "货币钟停机 · 网络超载"
                or generator.status == "jammed"
                    and "货币钟停机 · 传动冲突"
                    or generator.status == "isolated"
                        and "货币钟已啮合 · 尚未接入主轴"
                        or "货币钟等待远端齿轮连接"
    local miningMachine = networkState_.miningMachine
    local miningOreTotal = responsiveLayout_.NormalizeMiningInventory()
    local miningStatus = not miningMachine.electricPowered
        and "矿机等待发电机供电"
        or miningOreTotal
            >= GearDefinitions.MiningMachine.maxOre
        and string.format(
            "矿机矿仓已满 %d/%d",
            miningOreTotal,
            GearDefinitions.MiningMachine.maxOre
        )
        or miningMachine.miningEfficiency ~= nil
                and miningMachine.miningEfficiency > 0
            and string.format(
                "矿机 %.2f RPM · 效率 %.0f%% · 矿仓 %d/%d",
                miningMachine.rpm or 0,
                miningMachine.miningEfficiency * 100,
                miningOreTotal,
                GearDefinitions.MiningMachine.maxOre
            )
            or miningMachine.status == "insufficientTorque"
                and string.format(
                    "矿机扭矩不足 %.2f/%.2f",
                    miningMachine.torque or 0,
                    GearDefinitions.MiningMachine.requiredTorque
                )
                or miningMachine.status == "insufficientRPM"
                    and string.format(
                        "矿机转速不足 %.2f/%.0f RPM",
                        miningMachine.rpm or 0,
                        GearDefinitions.MiningMachine.minRPM
                    )
                    or miningMachine.status == "overspeed"
                        and string.format(
                            "矿机转速过高 %.2f/%.0f RPM",
                            miningMachine.rpm or 0,
                            GearDefinitions.MiningMachine.maxRPM
                        )
                        or miningMachine.status == "overloaded"
                            and "矿机停机 · 网络超载"
                            or miningMachine.status == "jammed"
                                and "矿机停机 · 传动卡死"
                                or miningMachine.status == "isolated"
                                    and "矿机已啮合 · 尚未接入主轴"
                                    or "矿机等待齿轮连接"
    powerStatusLabel_:SetText(string.format(
        "%s\n负载 %.2f / 扭矩 %.2f · 基建 %.2f\n%s\n%s",
        powerState,
        networkState_.totalLoad,
        networkState_.sourceTorque,
        networkState_.fixedLoad,
        generatorStatus,
        miningStatus
    ))
    local loadRatio = networkState_.totalLoad
        / math.max(
            GearDefinitions.Main.torquePerLevel,
            networkState_.sourceTorque
        )
    local clampedLoadRatio = math.min(1, math.max(0, loadRatio))
    loadProgressBar_:SetValue(clampedLoadRatio)
    loadGaugeLabel_:SetText(string.format(
        "当前负载 %.2f  /  总扭矩 %.2f  ·  %.0f%%",
        networkState_.totalLoad,
        networkState_.sourceTorque,
        loadRatio * 100
    ))
    if networkState_.overloaded then
        loadProgressBar_:SetStyle({ fillColor = { 255, 76, 70, 255 } })
        loadGaugeLabel_:SetStyle({ fontColor = { 255, 91, 82, 255 } })
    elseif loadRatio >= 0.75 then
        loadProgressBar_:SetStyle({ fillColor = { 255, 188, 61, 255 } })
        loadGaugeLabel_:SetStyle({ fontColor = { 255, 196, 79, 255 } })
    else
        loadProgressBar_:SetStyle({ fillColor = { 44, 222, 245, 255 } })
        loadGaugeLabel_:SetStyle({ fontColor = { 124, 207, 231, 245 } })
    end
    shopInfoLabel_:SetText(string.format(
        "已购 %d · 咬合 %d · 驱动 %d",
        #gameData_.revenueGears,
        networkState_.meshedCount,
        connectedGearCount_
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
    local ascensionVisible = ascensionPanel_
        and ascensionPanel_:IsVisible()
    local hasReward = gameData_.pendingOfflineCoins > 0
        and not ascensionVisible
    if hasReward then
        offlineRewardLabel_:SetText(string.format(
            "离线 %s\n累计 ￥%s",
            FormatDuration(gameData_.pendingOfflineSeconds),
            FormatNumber(gameData_.pendingOfflineCoins)
        ))
        claimOfflineButton_:SetText("领取奖励")
    end
    offlineRewardPanel_:SetVisible(hasReward)
end

RefreshUI = function()
    if responsiveLayout_.homeVisible then
        return
    end

    if networkState_.maintenanceJammed
        and CreateLubricantTutorialController then
        CreateLubricantTutorialController()
    end

    local clickValue = GetClickValue()
    local upgradeCost = GetUpgradeCost()
    local upgradeUnlocks = GearDefinitions.UpgradeRevealCoins
    local upgradeRailUnlockReached = gameData_.coins
            >= GearDefinitions.UpgradeRailUnlockCoins
        or gameData_.lifetimeCoinsEarned
            >= GearDefinitions.UpgradeRailUnlockCoins
    if not gameData_.upgradeRailPermanentlyUnlocked
        and upgradeRailUnlockReached then
        gameData_.upgradeRailPermanentlyUnlocked = true
        MarkSaveDirty(0)
        print("[Unlock] 升级侧栏已永久解锁")
    end
    local upgradeRailUnlocked =
        gameData_.upgradeRailPermanentlyUnlocked == true
    if responsiveLayout_.setUpgradeRailUnlocked then
        responsiveLayout_.setUpgradeRailUnlocked(upgradeRailUnlocked)
    end
    local torqueRevealed = IsUpgradeContentRevealed(
        "torque",
        gameData_.mainTorqueLevel
    )
    local circleIncomeRevealed = IsUpgradeContentRevealed(
        "circleIncome",
        gameData_.mainCircleIncomeLevel
    )
    local manualClickRevealed = IsUpgradeContentRevealed(
        "manualClick",
        gameData_.clickLevel - 1
    )
    local permanentUpgradeRevealed = IsUpgradeContentRevealed(
        "permanent",
        math.max(
            gameData_.globalIncomeLevel,
            gameData_.decayReductionLevel,
            gameData_.offlineIncomeLevel
        )
    )
    local function ApplyUpgradeCardRevealVisual(card, revealed)
        card.props.gearImage:SetVisible(revealed)
        card.props.lockedQuestionIcon:SetVisible(not revealed)
        card.props.actionLabel:SetText(revealed and "升级" or "未解锁")
        card.props.actionLabel:SetStyle({
            fontColor = revealed
                    and { 255, 225, 151, 255 }
                or { 170, 185, 191, 255 },
            backgroundColor = revealed
                    and { 84, 56, 17, 250 }
                or { 28, 38, 44, 245 },
            borderColor = revealed
                    and { 245, 187, 69, 245 }
                or { 91, 112, 122, 210 },
            borderWidth = 1,
        })
    end
    local lubricant = GearDefinitions.Get("lubricant")
    local smallPrice = GetGearPurchaseCost("small")
    local warehouseUnlockPrice = GearDefinitions.Get("small").purchaseCost
    local warehouseUnlockReached = gameData_.lifetimeCoinsEarned
            >= warehouseUnlockPrice
        or gameData_.coins >= warehouseUnlockPrice
        or #gameData_.revenueGears > 0
    if not gameData_.gearWarehousePermanentlyUnlocked
        and warehouseUnlockReached then
        gameData_.gearWarehousePermanentlyUnlocked = true
        MarkSaveDirty(0)
        print("[Unlock] 齿轮仓库侧栏已永久解锁")
    end
    local gearWarehouseUnlocked =
        gameData_.gearWarehousePermanentlyUnlocked == true
    if responsiveLayout_.setGearWarehouseUnlocked then
        responsiveLayout_.setGearWarehouseUnlocked(gearWarehouseUnlocked)
    end
    local mediumPrice = GetGearPurchaseCost("medium")
    local largePrice = GetGearPurchaseCost("large")
    local compoundPrice = GetGearPurchaseCost("compound")
    local mommaPrice = GetGearPurchaseCost("momma")
    local lubricantPrice = GetGearPurchaseCost("lubricant")
    local coinPrice = GetGearPurchaseCost("coin")

    coinLabel_:SetText("￥  " .. FormatNumber(gameData_.coins))
    local ascensionReward = GearDefinitions.GetAscensionReward(
        gameData_.runCoinsEarned
    )
    essenceLabel_:SetText(string.format(
        "精华 %s · +%s",
        FormatNumber(gameData_.gearEssence),
        FormatNumber(ascensionReward)
    ))
    clickValueLabel_:SetText(
        "每次点击  +￥" .. FormatCurrency(clickValue)
    )
    levelLabel_:SetText(string.format(
        "主齿轮：扭矩 Lv.%d · 自动单圈 Lv.%d · 点击 Lv.%d",
        gameData_.mainTorqueLevel,
        gameData_.mainCircleIncomeLevel,
        gameData_.clickLevel
    ))
    ApplyUpgradeCardRevealVisual(upgradeButton_, manualClickRevealed)
    if manualClickRevealed then
        if responsiveLayout_.mode == "landscape" then
            upgradeButton_:SetText(string.format(
                "点击收益\nLv.%d\n￥%s",
                gameData_.clickLevel,
                FormatNumber(upgradeCost)
            ))
        else
            upgradeButton_:SetText("提升点击收益\n查看详情")
        end
        upgradeButton_:SetDisabled(false)
        upgradeButton_:SetOpacity(1)
    else
        upgradeButton_:SetText(string.format(
            "未解锁\n未解锁\n￥%s",
            FormatNumber(upgradeUnlocks.manualClick)
        ))
        upgradeButton_:SetDisabled(true)
        upgradeButton_:SetOpacity(0.72)
    end

    local clickUpgradeConfirmButton =
        responsiveLayout_.clickUpgradeConfirmButton
    local clickUpgradeResultLabel = responsiveLayout_.clickUpgradeResultLabel
    if clickUpgradeConfirmButton and clickUpgradeResultLabel then
        local reachedClickMax = clickValue
            >= GearDefinitions.Main.manualClickMax
        local nextClickValue = math.min(
            GearDefinitions.Main.manualClickMax,
            clickValue * GearDefinitions.Main.manualClickGrowth
        )
        clickUpgradeResultLabel:SetText(string.format(
            "• 升级后每次点击立即获得￥%s",
            FormatCurrency(nextClickValue)
        ))
        clickUpgradeConfirmButton:SetText(
            reachedClickMax
                    and "已达上限"
                or string.format(
                    "升级  ￥%s",
                    FormatNumber(upgradeCost)
                )
        )
        clickUpgradeConfirmButton:SetDisabled(
            reachedClickMax or gameData_.coins < upgradeCost
        )
    end
    if responsiveLayout_.refreshMainUpgradeDetails then
        responsiveLayout_.refreshMainUpgradeDetails()
    end

    local torqueCost = GearDefinitions.GetMainUpgradeCost(
        "torque",
        gameData_.mainTorqueLevel
    )
    ApplyUpgradeCardRevealVisual(
        mainTorqueUpgradeButton_,
        torqueRevealed
    )
    if torqueRevealed then
        if responsiveLayout_.mode == "landscape" then
            mainTorqueUpgradeButton_:SetText(string.format(
                "主轴扭矩\nLv.%d\n￥%s",
                gameData_.mainTorqueLevel,
                FormatNumber(torqueCost)
            ))
        else
            mainTorqueUpgradeButton_:SetText(string.format(
                "给主齿轮力量 Lv.%d\n￥%s",
                gameData_.mainTorqueLevel,
                FormatNumber(torqueCost)
            ))
        end
        mainTorqueUpgradeButton_:SetDisabled(
            responsiveLayout_.mode ~= "landscape"
                and gameData_.coins < torqueCost
        )
        mainTorqueUpgradeButton_:SetOpacity(1)
    else
        mainTorqueUpgradeButton_:SetText(string.format(
            "未解锁\n未解锁\n￥%s",
            FormatNumber(upgradeUnlocks.torque)
        ))
        mainTorqueUpgradeButton_:SetDisabled(true)
        mainTorqueUpgradeButton_:SetOpacity(0.72)
    end

    local circleCost = GearDefinitions.GetMainUpgradeCost(
        "circleIncome",
        gameData_.mainCircleIncomeLevel
    )
    ApplyUpgradeCardRevealVisual(
        mainCircleIncomeUpgradeButton_,
        circleIncomeRevealed
    )
    if circleIncomeRevealed then
        if responsiveLayout_.mode == "landscape" then
            mainCircleIncomeUpgradeButton_:SetText(string.format(
                "单个主齿轮收益\nLv.%d\n￥%s",
                gameData_.mainCircleIncomeLevel,
                FormatNumber(circleCost)
            ))
        else
            mainCircleIncomeUpgradeButton_:SetText(string.format(
                "单个中央主齿轮收益 Lv.%d\n￥%s",
                gameData_.mainCircleIncomeLevel,
                FormatNumber(circleCost)
            ))
        end
        mainCircleIncomeUpgradeButton_:SetDisabled(
            responsiveLayout_.mode ~= "landscape"
                and gameData_.coins < circleCost
        )
        mainCircleIncomeUpgradeButton_:SetOpacity(1)
    else
        mainCircleIncomeUpgradeButton_:SetText(string.format(
            "未解锁\n未解锁\n￥%s",
            FormatNumber(upgradeUnlocks.circleIncome)
        ))
        mainCircleIncomeUpgradeButton_:SetDisabled(true)
        mainCircleIncomeUpgradeButton_:SetOpacity(0.72)
    end

    if responsiveLayout_.setPermanentUpgradeRevealed then
        responsiveLayout_.setPermanentUpgradeRevealed(
            permanentUpgradeRevealed,
            "￥" .. FormatNumber(upgradeUnlocks.permanent)
        )
    end
    if permanentUpgradeRevealed then
        if responsiveLayout_.mode == "landscape" then
            globalUpgradeOpenButton_:SetText("")
            if responsiveLayout_.permanentUpgradeLevelLabel then
                responsiveLayout_.permanentUpgradeLevelLabel:SetText(string.format(
                    "Lv.%d",
                    gameData_.globalIncomeLevel
                ))
            end
        else
            globalUpgradeOpenButton_:SetText("永久强化")
        end
        globalUpgradeOpenButton_:SetDisabled(false)
        globalUpgradeOpenButton_:SetOpacity(1)
    else
        globalUpgradeOpenButton_:SetText("")
        if responsiveLayout_.permanentUpgradeLevelLabel then
            responsiveLayout_.permanentUpgradeLevelLabel:SetText("未解锁")
        end
        globalUpgradeOpenButton_:SetDisabled(true)
        globalUpgradeOpenButton_:SetOpacity(0.72)
    end

    local smallRevealed = IsShopGearRevealed("small")
    local mediumRevealed = IsShopGearRevealed("medium")
    local largeRevealed = IsShopGearRevealed("large")
    local compoundRevealed = IsShopGearRevealed("compound")
    local mommaRevealed = IsShopGearRevealed("momma")
    local lubricantRevealed = IsShopGearRevealed("lubricant")
    local coinRevealed = IsShopGearRevealed("coin")

    local function UpdateShopGearReveal(card, revealed, unlockPrice)
        if responsiveLayout_.setShopGearRevealed then
            responsiveLayout_.setShopGearRevealed(
                card,
                revealed,
                "￥" .. FormatNumber(unlockPrice)
            )
        end
    end
    buySmallGearPriceLabel_:SetText("￥" .. FormatNumber(smallPrice))
    buySmallGearButton_:SetClickable(true)
    buySmallGearButton_:SetOpacity(gameData_.coins >= smallPrice and 1 or 0.72)
    buyMediumGearPriceLabel_:SetText("￥" .. FormatNumber(mediumPrice))
    buyMediumGearButton_:SetClickable(true)
    buyMediumGearButton_:SetOpacity(gameData_.coins >= mediumPrice and 1 or 0.72)
    buyLargeGearPriceLabel_:SetText("￥" .. FormatNumber(largePrice))
    buyLargeGearButton_:SetClickable(true)
    buyLargeGearButton_:SetOpacity(gameData_.coins >= largePrice and 1 or 0.72)

    buyCompoundGearPriceLabel_:SetText(
        "￥" .. FormatNumber(compoundPrice)
    )
    buyCompoundGearButton_:SetClickable(true)
    buyCompoundGearButton_:SetOpacity(
        gameData_.coins >= compoundPrice and 1 or 0.72
    )
    buyMommaGearPriceLabel_:SetText(
        "￥" .. FormatNumber(mommaPrice)
    )
    buyMommaGearButton_:SetClickable(true)
    buyMommaGearButton_:SetOpacity(
        gameData_.coins >= mommaPrice and 1 or 0.72
    )
    responsiveLayout_.buyCoinGearPriceLabel:SetText(
        "￥" .. FormatNumber(coinPrice)
    )
    responsiveLayout_.buyCoinGearButton:SetClickable(true)
    responsiveLayout_.buyCoinGearButton:SetOpacity(
        gameData_.coins >= coinPrice and 1 or 0.72
    )
    local lubricantCooldown = math.max(
        0,
        gameData_.lubricantCooldownRemaining or 0
    )
    local lubricantInUse = HasActiveLubricantGear()
    responsiveLayout_.lubricantCooldownDisplaySecond =
        math.ceil(lubricantCooldown)
    if lubricantCooldown > 0 then
        responsiveLayout_.buyLubricantGearButton.props.modelLabel:SetText(
            "OIL-08  冷却中"
        )
        responsiveLayout_.buyLubricantGearPriceLabel:SetText(string.format(
            "CD %ds",
            math.ceil(lubricantCooldown)
        ))
        responsiveLayout_.buyLubricantGearButton:SetClickable(false)
        responsiveLayout_.buyLubricantGearButton:SetOpacity(0.45)
    elseif lubricantInUse then
        responsiveLayout_.buyLubricantGearButton.props.modelLabel:SetText(
            "OIL-08  巡游中"
        )
        responsiveLayout_.buyLubricantGearPriceLabel:SetText("使用中")
        responsiveLayout_.buyLubricantGearButton:SetClickable(false)
        responsiveLayout_.buyLubricantGearButton:SetOpacity(0.55)
    else
        responsiveLayout_.buyLubricantGearButton.props.modelLabel:SetText(
            "OIL-08  巡游润滑"
        )
        responsiveLayout_.buyLubricantGearPriceLabel:SetText(string.format(
            "￥%s · CD %ds",
            FormatNumber(lubricantPrice),
            lubricant.cooldownSeconds
        ))
        responsiveLayout_.buyLubricantGearButton:SetClickable(true)
        responsiveLayout_.buyLubricantGearButton:SetOpacity(
            gameData_.coins >= lubricantPrice and 1 or 0.72
        )
    end

    UpdateShopGearReveal(
        buySmallGearButton_,
        smallRevealed,
        GearDefinitions.Get("small").purchaseCost
    )
    UpdateShopGearReveal(
        buyMediumGearButton_,
        mediumRevealed,
        GearDefinitions.Get("medium").purchaseCost
    )
    UpdateShopGearReveal(
        buyLargeGearButton_,
        largeRevealed,
        GearDefinitions.Get("large").purchaseCost
    )
    UpdateShopGearReveal(
        buyCompoundGearButton_,
        compoundRevealed,
        GearDefinitions.Get("compound").purchaseCost
    )
    UpdateShopGearReveal(
        buyMommaGearButton_,
        mommaRevealed,
        GearDefinitions.Get("momma").purchaseCost
    )
    UpdateShopGearReveal(
        responsiveLayout_.buyLubricantGearButton,
        lubricantRevealed,
        GearDefinitions.Get("lubricant").purchaseCost
    )
    UpdateShopGearReveal(
        responsiveLayout_.buyCoinGearButton,
        coinRevealed,
        GearDefinitions.Get("coin").purchaseCost
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
            "巨型工厂 · 库存 %d/%d\n下一枚 %s · 飞升提速 %.0f%% · 固定负载 %.2f",
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
            "巨型工厂 · 未解锁\n消耗精华解锁 · 固定负载 %.2f",
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

    if responsiveLayout_.idleEarningsButton then
        local now = os.time()
        local request = responsiveLayout_.idleAdRequest
        RefreshIdleAdDay(now)
        if request.inFlight then
            responsiveLayout_.idleEarningsButton:SetText("广告播放中")
            responsiveLayout_.idleEarningsButton:SetDisabled(true)
            responsiveLayout_.idleEarningsButton:SetOpacity(0.72)
        elseif IsIdleEarningsUnlocked(now) then
            responsiveLayout_.idleEarningsButton:SetText("挂机 已开启")
            responsiveLayout_.idleEarningsButton:SetDisabled(false)
            responsiveLayout_.idleEarningsButton:SetOpacity(1)
        else
            responsiveLayout_.idleEarningsButton:SetText(string.format(
                "挂机 %d/2",
                gameData_.idleAdWatchCount or 0
            ))
            responsiveLayout_.idleEarningsButton:SetDisabled(false)
            responsiveLayout_.idleEarningsButton:SetOpacity(0.88)
        end
    end

    if gameData_.autoDriveUnlocked then
        autoDriveButton_:SetText(
            responsiveLayout_.mode == "landscape"
                and "自动运转"
                or "自动运转 · 0.03 圈/秒"
        )
        autoDriveButton_:SetDisabled(false)
        autoDriveButton_:SetOpacity(1)
    else
        if responsiveLayout_.mode == "landscape" then
            autoDriveButton_:SetText(string.format(
                "Lv.%d 解锁",
                GearDefinitions.Main.autoUnlockTorqueLevel
            ))
        else
            autoDriveButton_:SetText(string.format(
                "扭矩 Lv.%d 解锁自动运转",
                GearDefinitions.Main.autoUnlockTorqueLevel
            ))
        end
        autoDriveButton_:SetDisabled(false)
        autoDriveButton_:SetOpacity(0.72)
    end

    RefreshRevenueUI()
    RefreshSelectedGearUI()
    RefreshGlobalUpgradeUI()
    local currentAscensionReward = GearDefinitions.GetAscensionReward(
        gameData_.runCoinsEarned
    )
    if responsiveLayout_.mode == "landscape" then
        ascensionOpenButton_:SetText("飞升重构")
    else
        ascensionOpenButton_:SetText(string.format(
            "飞升重构  +%s精华",
            FormatNumber(currentAscensionReward)
        ))
    end
    ascensionRewardLabel_:SetText(string.format(
        "本次预计获得 %s 齿轮精华",
        FormatNumber(currentAscensionReward)
    ))
    ascensionProgressLabel_:SetText(string.format(
        "本局实际赚取 ￥%s\n每 ￥%s = 1 精华（当前余额不计入）\n历史 %s · 飞升 %d 次",
        FormatNumber(gameData_.runCoinsEarned),
        FormatNumber(GearDefinitions.Ascension.essenceCoinRatio),
        FormatNumber(gameData_.lifetimeCoinsEarned),
        gameData_.ascensionCount
    ))
    ascensionConfirmButton_:SetText(
        currentAscensionReward > 0
            and "确认飞升"
            or "查看飞升条件"
    )
    ascensionConfirmButton_:SetDisabled(false)
    RefreshOfflineRewardUI()
end

RebuildGearNetwork = function(reason, logChange)
    local previousConnectedCount = connectedGearCount_
    local previousIncome = totalIncomePerSecond_
    ---@type GearNetworkState
    local rebuiltState
    local generator = networkState_.currencyGenerator
    local miningMachine = networkState_.miningMachine
    local powerGeneratorInterface = networkState_.powerGeneratorInterface
    local powerGeneratorDisplay = networkState_.powerGeneratorDisplay
    local clockInterface = networkState_.clockInterface
    local clockDisplay = networkState_.clockDisplay
    clockInterface.assetUnlocked = gameData_.lifetimeCoinsEarned
        >= GearDefinitions.ClockInterface.requiredLifetimeCoins
    powerGeneratorInterface.assetUnlocked = gameData_.lifetimeCoinsEarned
        >= GearDefinitions.MiningMachine.requiredLifetimeCoins
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
        {},
        gameData_.unlockedBuildings.precisionFoundry == true
            and GearDefinitions.MommaFactory.fixedLoad
            or 0,
        { generator, powerGeneratorInterface, clockInterface }
    )
    miningMachine.meshed = false
    miningMachine.connected = false
    miningMachine.powered = false
    miningMachine.electricPowered = false
    miningMachine.jammed = false
    miningMachine.overloaded = false
    miningMachine.rpm = 0
    miningMachine.spinDirection = 0
    miningMachine.torque = 0
    miningMachine.transmissionDepth = 0
    miningMachine.parentIndex = nil
    miningMachine.inputRing = nil
    miningMachine.status = "powerOff"
    rebuiltState.currencyGenerator = generator
    rebuiltState.miningMachine = miningMachine
    rebuiltState.powerGeneratorInterface = powerGeneratorInterface
    rebuiltState.powerGeneratorDisplay = powerGeneratorDisplay
    rebuiltState.clockInterface = clockInterface
    rebuiltState.clockDisplay = clockDisplay
    clockInterface.running = clockInterface.powered == true
    clockDisplay.running = clockInterface.running
    clockDisplay.interfaceX = clockInterface.x
    clockDisplay.interfaceY = clockInterface.y
    clockDisplay.gearAngle = clockInterface.angle or 0
    powerGeneratorDisplay.powered = powerGeneratorInterface.powered == true
    powerGeneratorDisplay.status = powerGeneratorInterface.status
    powerGeneratorDisplay.rpm = powerGeneratorInterface.rpm
    powerGeneratorDisplay.spinDirection = powerGeneratorInterface.spinDirection
    powerGeneratorDisplay.gearAngle = powerGeneratorInterface.angle or 0
    networkState_ = rebuiltState
    networkState_.transmissionIncomePerSecond = 0
    local coinIncomePerSecond = 0
    if not networkState_.jammed and not networkState_.overloaded then
        for gearIndex, gear in ipairs(gameData_.revenueGears) do
            if gear.gearType == "coin" and gear.connected then
                local definition = GearDefinitions.Get("coin")
                gear.incomePerSecond = definition.baseRewardPerTurn
                    * GetGlobalIncomeMultiplier()
                    * GetClockIncomeMultiplierForGearIndex(gearIndex)
                    * gear.rpm
                    / 60
                coinIncomePerSecond = coinIncomePerSecond
                    + gear.incomePerSecond
            else
                gear.incomePerSecond = 0
            end
        end
    else
        for _, gear in ipairs(gameData_.revenueGears) do
            gear.incomePerSecond = 0
        end
    end
    networkState_.transmissionIncomePerSecond = coinIncomePerSecond
    networkState_.mainIncomePerSecond =
            gameData_.autoDriveUnlocked
                and not networkState_.jammed
                and not networkState_.overloaded
        and GetMainIncomePerSecond()
        or 0
    totalIncomePerSecond_ = networkState_.mainIncomePerSecond
        + networkState_.transmissionIncomePerSecond

    if previousConnectedCount ~= connectedGearCount_
        or math.abs(previousIncome - totalIncomePerSecond_) > 0.0001 then
        responsiveLayout_.incomeLeaderboardDirty = true
        responsiveLayout_.incomeLeaderboardSyncTimer = math.min(
            responsiveLayout_.incomeLeaderboardSyncTimer,
            CONFIG.IncomeLeaderboardSyncDelay
        )
        RefreshRevenueUI()
    end
    RefreshSelectedGearUI()
    if networkState_.maintenanceJammed
        and CreateLubricantTutorialController then
        CreateLubricantTutorialController()
    end
    if responsiveLayout_.tutorial
        and responsiveLayout_.tutorial:IsActive()
        and gameData_.tutorialStep == "completed" then
        responsiveLayout_.tutorial = nil
    end

    if logChange then
        print(string.format(
            "[GearNetwork] %s: connected=%d, edges=%d, mainIncome=%.2f/s, coinIncome=%.2f/s, totalIncome=%.2f/s, jammed=%s",
            reason,
            connectedGearCount_,
            #connections_,
            networkState_.mainIncomePerSecond,
            networkState_.transmissionIncomePerSecond,
            totalIncomePerSecond_,
            tostring(networkState_.jammed)
        ))
    end
end

local function RefreshLayout()
    physicalWidth_ = graphics:GetWidth()
    physicalHeight_ = graphics:GetHeight()
    dpr_ = math.max(graphics:GetDPR(), 1)
    local screenLogicalWidth = physicalWidth_ / dpr_
    local screenLogicalHeight = physicalHeight_ / dpr_
    local isLandscape = responsiveLayout_.mode == "landscape"
    local rotatePortrait = not isLandscape
        and physicalWidth_ >= physicalHeight_
    responsiveLayout_.rotatePortrait = rotatePortrait
    responsiveLayout_.screenLogicalWidth = screenLogicalWidth
    responsiveLayout_.screenLogicalHeight = screenLogicalHeight
    logicalWidth_ = rotatePortrait
            and screenLogicalHeight
        or screenLogicalWidth
    logicalHeight_ = rotatePortrait
            and screenLogicalWidth
        or screenLogicalHeight

    local uiScale = math.max(UI.GetScale(), 0.01)
    local screenUIWidth = physicalWidth_ / uiScale
    local screenUIHeight = physicalHeight_ / uiScale
    local uiWidth = rotatePortrait and screenUIHeight or screenUIWidth
    local uiHeight = rotatePortrait and screenUIWidth or screenUIHeight
    responsiveLayout_.screenUIWidth = screenUIWidth
    responsiveLayout_.screenUIHeight = screenUIHeight
    local uiToLogical = uiScale / dpr_
    local sideGap = 0
    -- 横屏 HUD 改为悬浮覆盖层，画布不再为左右功能栏预留空间。
    local leftRailWidth = 0
    local rightRailWidth = 0

    local canvasLeft = isLandscape
        and (leftRailWidth + sideGap) * uiToLogical
        or 0
    local canvasRight = isLandscape
        and logicalWidth_
            - (rightRailWidth + sideGap) * uiToLogical
        or logicalWidth_
    local canvasWidth = math.max(160, canvasRight - canvasLeft)
    local canvasHeight = logicalHeight_
    responsiveLayout_.canvasLeft = canvasLeft
    responsiveLayout_.canvasRight = canvasRight
    if responsiveLayout_.apply then
        responsiveLayout_.apply({
            mode = responsiveLayout_.mode,
            width = uiWidth,
            height = uiHeight,
            uiScale = uiScale,
            leftRailWidth = leftRailWidth,
            rightRailWidth = rightRailWidth,
        })
    end

    mainGearX_ = canvasLeft + canvasWidth * 0.5
    mainGearY_ = canvasHeight * 0.52
    mainGearRadius_ = math.min(
        canvasWidth * 0.115,
        canvasHeight * 0.065,
        62
    )
    revenueGearRadius_ = mainGearRadius_
    meshTolerance_ = math.max(4, mainGearRadius_ * 0.07)
    snapTolerance_ = math.max(28, mainGearRadius_ * 0.45)
    canvasMinY_ = 0
    canvasMaxY_ = logicalHeight_

    local generator = networkState_.currencyGenerator
    local generatorDefinition = GearDefinitions.CurrencyGenerator
    generator.radius = mainGearRadius_ * generatorDefinition.radiusScale
    generator.imageWidth = mainGearRadius_ * 3.1
    generator.imageHeight = generator.imageWidth * 1.5

    generator.x = mainGearX_
        + mainGearRadius_ * generatorDefinition.xOffsetInMainRadii
    generator.y = mainGearY_
        + mainGearRadius_ * generatorDefinition.yOffsetInMainRadii
    generator.bodyWidth = generator.imageWidth * 0.76
    generator.bodyHeight = generator.imageHeight * 0.55
    generator.bodyX = generator.x
    generator.bodyY = generator.y - generator.imageHeight * 0.36

    local miningMachine = networkState_.miningMachine
    local miningDefinition = GearDefinitions.MiningMachine
    miningMachine.radius = mainGearRadius_ * miningDefinition.radiusScale
    miningMachine.imageWidth = mainGearRadius_ * 9.8
    miningMachine.imageHeight = miningMachine.imageWidth
    miningMachine.x = mainGearX_
        + mainGearRadius_ * miningDefinition.xOffsetInMainRadii
    miningMachine.y = mainGearY_
        + mainGearRadius_ * miningDefinition.yOffsetInMainRadii
    miningMachine.bodyWidth = miningMachine.imageWidth * 0.92
    miningMachine.bodyHeight = miningMachine.imageHeight * 0.94
    miningMachine.bodyX = miningMachine.x
    miningMachine.bodyY = miningMachine.y - miningMachine.imageHeight * 0.32

    networkState_.powerGeneratorDisplay.width = mainGearRadius_ * 8.0
    networkState_.powerGeneratorDisplay.height =
        networkState_.powerGeneratorDisplay.width * 0.75
    local interfaceDefinition = GearDefinitions.PowerGeneratorInterface
    networkState_.powerGeneratorInterface.radius =
        mainGearRadius_ * interfaceDefinition.radiusScale
    networkState_.powerGeneratorDisplay.gearSize =
        GearDefinitions.GetTipRadius(
            networkState_.powerGeneratorInterface.radius,
            interfaceDefinition.rings.outer.teeth
        ) * 2 / 0.91
    networkState_.powerGeneratorDisplay.x =
        mainGearX_ + mainGearRadius_ * 30.0
    networkState_.powerGeneratorDisplay.y =
        mainGearY_ + mainGearRadius_ * 0.4
    networkState_.powerGeneratorDisplay.interfaceX = nil
    networkState_.powerGeneratorDisplay.interfaceY = nil
    networkState_.powerGeneratorInterface.x =
        networkState_.powerGeneratorDisplay.x
    networkState_.powerGeneratorInterface.y =
        networkState_.powerGeneratorDisplay.y
            + networkState_.powerGeneratorDisplay.height * 0.15
    networkState_.powerGeneratorInterface.bodyX = nil
    networkState_.powerGeneratorInterface.bodyY = nil
    networkState_.powerGeneratorInterface.bodyWidth = nil
    networkState_.powerGeneratorInterface.bodyHeight = nil

    local clockInterface = networkState_.clockInterface
    local clockDisplay = networkState_.clockDisplay
    local clockDefinition = GearDefinitions.ClockInterface
    clockInterface.radius = mainGearRadius_ * clockDefinition.radiusScale
    clockDisplay.width = mainGearRadius_ * 6.2
    clockDisplay.height = clockDisplay.width
    clockDisplay.x = mainGearX_ - mainGearRadius_ * 27.6
    clockDisplay.y = mainGearY_ + mainGearRadius_ * 2.0
    clockInterface.x = clockDisplay.x - clockDisplay.width * 0.20
    clockInterface.y = clockDisplay.y + clockDisplay.height * 0.19
    clockDisplay.interfaceX = clockInterface.x
    clockDisplay.interfaceY = clockInterface.y
    clockDisplay.gearSize = GearDefinitions.GetTipRadius(
        clockInterface.radius,
        clockDefinition.rings.outer.teeth
    ) * 2 / 0.91

    local migratedGearAnchors = false
    for _, gear in ipairs(gameData_.revenueGears) do
        local definition = GearDefinitions.Get(gear.gearType)
        gear.teeth = definition.teeth
        gear.radius = revenueGearRadius_ * definition.radiusScale
        local hasAnchor = type(gear.anchorX) == "number"
            and type(gear.anchorY) == "number"
        if hasAnchor then
            gear.x = mainGearX_ + gear.anchorX * mainGearRadius_
            gear.y = mainGearY_ + gear.anchorY * mainGearRadius_
        else
            gear.x = isLandscape
                    and canvasLeft + gear.xNorm * canvasWidth
                or gear.xNorm * logicalWidth_
            gear.y = gear.yNorm * logicalHeight_
            migratedGearAnchors = true
        end
        gear.angle = gear.angle or 0
        gear.connected = false
        gear.meshed = false
        gear.jammed = false
        gear.spinDirection = 0
        gear.rpm = 0
        gear.rpmRatio = 0
        gear.torque = 0
        gear.incomePerSecond = 0
        gear.turnProgress = math.max(
            0,
            math.min(0.999999, gear.turnProgress or 0)
        )
        gear.lubricationRemaining = math.max(
            0,
            gear.lubricationRemaining
                or (
                    definition.type == "lubricant"
                        and GearDefinitions.GetLubricationDuration(
                            gear.level
                        )
                )
                or definition.lubricationDuration
                or GearDefinitions.DefaultLubricationDuration
        )
        gear.lubricated = false
        gear.lubricationSource = false
        gear.maintenanceJammed = false
        gear.autonomous = definition.type == "lubricant"
        gear.patrolTargetCursor = math.max(1, gear.patrolTargetCursor or 1)
        gear.patrolState = gear.patrolState or "travel"
        gear.patrolOrbitAngle = gear.patrolOrbitAngle or 0
        gear.patrolOrbitTravel = gear.patrolOrbitTravel or 0
        gear.oilEffectRemaining = 0
        gear.transmissionDepth = 0
        gear.parentIndex = nil
        UpdateGearNormalizedPosition(gear)
    end

    local geometryMigratedAfterLayout = GearGeometryMigration.Migrate(gameData_)
    if geometryMigratedAfterLayout then
        for _, gear in ipairs(gameData_.revenueGears) do
            gear.x = mainGearX_ + gear.anchorX * mainGearRadius_
            gear.y = mainGearY_ + gear.anchorY * mainGearRadius_
            UpdateGearNormalizedPosition(gear)
        end
        MarkSaveDirty(0)
        print("[Layout] 已按新尺寸体系重排旧存档齿轮网络")
    end

    RebuildGearNetwork("屏幕布局更新", true)
    if migratedGearAnchors then
        MarkSaveDirty()
        print("[Layout] 已将旧齿轮坐标迁移为主齿轮相对锚点")
    end

    print(string.format(
        "[Layout] physical=%dx%d, dpr=%.2f, nvg=%.1fx%.1f, uiScale=%.3f, ui=%.1fx%.1f, rotated=%s, rails=%.1f/%.1f, mainRadius=%.1f",
        physicalWidth_,
        physicalHeight_,
        dpr_,
        logicalWidth_,
        logicalHeight_,
        uiScale,
        uiWidth,
        uiHeight,
        tostring(rotatePortrait),
        leftRailWidth,
        rightRailWidth,
        mainGearRadius_
    ))
end

local function CreditManualMainGearClick()
    local displayedReward = GetClickValue()
    gameData_.manualClickIncomeRemainder =
        gameData_.manualClickIncomeRemainder + displayedReward
    local payableReward = math.floor(
        gameData_.manualClickIncomeRemainder
    )
    gameData_.manualClickIncomeRemainder =
        gameData_.manualClickIncomeRemainder - payableReward
    local reward = CreditCoins(payableReward)

    mainGearPulse_ = 1
    incomeEffects_.SpawnPopup(
        mainGearX_,
        mainGearY_,
        mainGearRadius_,
        displayedReward,
        FormatCurrency(displayedReward)
    )
    RefreshUI()
    MarkSaveDirty()

    print(string.format(
        "[Economy] 点击主齿轮: 产生￥%s, 入账￥%d, 余数￥%.2f",
        FormatCurrency(displayedReward),
        reward,
        gameData_.manualClickIncomeRemainder
    ))
    NotifyTutorial("main_clicked")
end

function FinishIdleAdRequest(token, result)
    local request = responsiveLayout_.idleAdRequest
    if request.token ~= token or request.inFlight ~= true then
        return
    end

    request.inFlight = false
    request.deadline = 0
    local success = result and result.success == true
    if success then
        local now = os.time()
        RefreshIdleAdDay(now)
        if (gameData_.idleAdWatchCount or 0) < 2 then
            gameData_.idleAdWatchCount = gameData_.idleAdWatchCount + 1
        end
        if gameData_.idleAdWatchCount >= 2 then
            gameData_.idleEligibleUntil = GetIdleDayEndTimestamp(now)
        end
        MarkSaveDirty(0)
        SaveNow("激励广告挂机进度")
        RefreshUI()
        UI.Modal.Alert({
            title = gameData_.idleAdWatchCount >= 2
                    and "今日挂机已开启"
                or "广告进度已记录",
            message = gameData_.idleAdWatchCount >= 2
                    and string.format(
                        "今日已完成 2/2 次广告。\n退出或切到后台后，将按当前真实平均产能计算挂机收益，最多累计8小时，并在今日结束时截止。\n当前产能：￥%s/秒",
                        FormatCurrency(totalIncomePerSecond_)
                    )
                or string.format(
                    "今日已完成 %d/2 次广告。\n再完整观看1次即可开启今日挂机收益。",
                    gameData_.idleAdWatchCount
                ),
            buttonText = "知道了",
        })
        print(string.format(
            "[Idle] 激励广告成功: progress=%d/2, eligibleUntil=%d",
            gameData_.idleAdWatchCount,
            gameData_.idleEligibleUntil
        ))
        return
    end

    RefreshUI()
    local message = result and result.msg or "广告暂不可用，请稍后重试"
    if message == "embed manual close" then
        message = "需要完整观看广告才会记录挂机进度。"
    else
        message = "广告未完成，挂机进度没有增加。请稍后重试。"
    end
    UI.Modal.Alert({
        title = "广告未完成",
        message = message,
        buttonText = "知道了",
    })
    print("[Idle] 激励广告失败: " .. tostring(result and result.msg))
end

function RequestIdleRewardAd()
    local request = responsiveLayout_.idleAdRequest
    if request.inFlight then
        return
    end

    local now = os.time()
    if GetIdleAdsRemaining(now) <= 0 then
        RefreshUI()
        return
    end

    request.token = request.token + 1
    local token = request.token
    request.inFlight = true
    request.deadline = 0
    RefreshUI()

    local callbackFired = false
    local hostSdk = rawget(_G, "sdk")
    if not hostSdk or type(hostSdk.ShowRewardVideoAd) ~= "function" then
        FinishIdleAdRequest(token, {
            success = false,
            msg = "当前环境不支持激励广告",
        })
        return
    end
    local accepted = hostSdk:ShowRewardVideoAd(function(result)
        callbackFired = true
        FinishIdleAdRequest(token, result)
    end)
    if accepted == false and not callbackFired then
        FinishIdleAdRequest(token, {
            success = false,
            msg = "广告暂不可用，请稍后重试",
        })
    elseif accepted ~= false and request.inFlight then
        request.deadline = os.time() + 120
    end
end

function OpenIdleEarnings()
    local now = os.time()
    RefreshIdleAdDay(now)
    if responsiveLayout_.idleAdRequest.inFlight then
        return
    end

    if IsIdleEarningsUnlocked(now) then
        UI.Modal.Alert({
            title = "今日挂机已开启",
            message = string.format(
                "今日广告进度 2/2。\n退出或切到后台后，将按当前真实平均产能计算挂机收益，最多累计8小时，并在今日结束时截止。\n当前产能：￥%s/秒",
                FormatCurrency(totalIncomePerSecond_)
            ),
            buttonText = "知道了",
        })
        return
    end

    local watched = gameData_.idleAdWatchCount or 0
    UI.Modal.Confirm({
        title = "开启今日挂机",
        message = string.format(
            "今日广告进度 %d/2。\n每次必须完整观看才会计入进度；看满2次后，今日退出或切到后台也会按当前真实平均产能累计收益。\n提前关闭或播放失败不会计次。",
            watched
        ),
        confirmText = "观看广告",
        cancelText = "暂不开启",
        onConfirm = RequestIdleRewardAd,
    })
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
    CloseTransientPopups()
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
    manualRotationActive_ = 0
    responsiveLayout_.manualMainGearTurnsRemaining = 0
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
    if responsiveLayout_.hideMainUpgradeDetails then
        responsiveLayout_.hideMainUpgradeDetails()
    end
    NotifyTutorial("torque_upgraded")
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
    if GetClickValue() >= GearDefinitions.Main.manualClickMax then
        print("[Game] 点击收益已达到上限")
        return
    end

    local cost = GetUpgradeCost()
    if gameData_.coins < cost then
        print(string.format("[Game] 升级余额不足: 当前=%d, 需要=%d", gameData_.coins, cost))
        return
    end

    gameData_.coins = gameData_.coins - cost
    gameData_.clickLevel = gameData_.clickLevel + 1

    print(string.format(
        "[Game] 点击收益升级成功: level=%d, clickValue=￥%s, coins=%d",
        gameData_.clickLevel,
        FormatCurrency(GetClickValue()),
        gameData_.coins
    ))

    RefreshUI()
    MarkSaveDirty()
    SaveNow("升级完成")
end

local function FindPurchaseSpawnPosition(radius)
    local gearIndex = #gameData_.revenueGears
    local maximumRadiusScale = GearDefinitions.Revenue.momma.radiusScale
    local spacing = mainGearRadius_ * (maximumRadiusScale * 2 + 0.35)
    local availableWidth = math.max(
        spacing,
        responsiveLayout_.canvasRight
            - responsiveLayout_.canvasLeft
            - radius * 2
    )
    local columns = math.max(1, math.floor(availableWidth / spacing))
    local column = gearIndex % columns
    local row = math.floor(gearIndex / columns) % 2
    local totalWidth = (columns - 1) * spacing
    local x = mainGearX_ - totalWidth * 0.5 + column * spacing
    local y = canvasMaxY_ - radius - 18 - row * spacing
    return x, y
end

local function CreateRevenueGearAt(
    gearType,
    source,
    spawnX,
    spawnY,
    spawnAngle,
    purchaseCostPaid
)
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
        anchorX = nil,
        anchorY = nil,
        x = spawnX,
        y = spawnY,
        radius = radius,
        teeth = definition.teeth,
        angle = spawnAngle or 0,
        connected = false,
        meshed = false,
        jammed = false,
        spinDirection = 0,
        rpm = 0,
        rpmRatio = 0,
        torque = 0,
        incomePerSecond = 0,
        turnProgress = 0,
        lubricationRemaining = definition.type == "lubricant"
                and GearDefinitions.GetLubricationDuration(1)
            or definition.lubricationDuration
            or GearDefinitions.DefaultLubricationDuration,
        lubricated = false,
        lubricationSource = false,
        maintenanceJammed = false,
        autonomous = definition.type == "lubricant",
        patrolTargetCursor = 1,
        patrolState = "travel",
        patrolOrbitAngle = 0,
        patrolOrbitTravel = 0,
        oilEffectRemaining = 0,
        transmissionDepth = 0,
        parentIndex = nil,
        inputRing = nil,
        load = 0,
        layerSpeedFactor = 0,
        speedCapped = false,
        overloaded = false,
        purchaseCostPaid = purchaseCostPaid,
    }

    gameData_.nextGearId = gameData_.nextGearId + 1
    gameData_.revenueGears[#gameData_.revenueGears + 1] = gear
    local gearIndex = #gameData_.revenueGears
    selectedGearIndex_ = nil
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

function GetFixedTransmissionAnchors()
    local anchors = {
        networkState_.currencyGenerator,
    }
    if networkState_.powerGeneratorInterface
        and networkState_.powerGeneratorInterface.visible ~= false then
        anchors[#anchors + 1] = networkState_.powerGeneratorInterface
    end
    if networkState_.clockInterface
        and networkState_.clockInterface.visible ~= false then
        anchors[#anchors + 1] = networkState_.clockInterface
    end
    return anchors
end

function ClearShopDragState()
    shopDrag_.gearType = nil
    shopDrag_.pointerId = nil
    shopDrag_.pointerType = nil
    shopDrag_.activated = false
    shopDrag_.overCanvas = false
    shopDrag_.placementValid = false
    shopDrag_.angle = 0
    shopDrag_.snapped = false
    shopDrag_.snapAnchorIndex = nil
    shopDrag_.axleTargetIndex = nil
end

function ResolveShopSnapAngle(
    gearType,
    worldX,
    worldY,
    draggedRingName,
    anchorRingName,
    anchorIndex
)
    if anchorIndex == nil
        or draggedRingName == nil
        or anchorRingName == nil then
        return 0
    end

    local anchorX = mainGearX_
    local anchorY = mainGearY_
    local anchorType = "main"
    local anchorAngle = mainGearAngle_
    if type(anchorIndex) == "number" and anchorIndex > 0 then
        local anchorGear = gameData_.revenueGears[anchorIndex]
        if not anchorGear then
            return 0
        end
        local visualAngles = GearRenderer.ResolveVisualAngles(
            gameData_.revenueGears,
            connections_,
            mainGearX_,
            mainGearY_,
            mainGearAngle_,
            networkState_.externalNodes
        )
        anchorX = anchorGear.x
        anchorY = anchorGear.y
        anchorType = anchorGear.gearType
        anchorAngle = visualAngles[anchorIndex] or anchorGear.angle
    elseif type(anchorIndex) == "string" then
        local externalNode = networkState_.externalNodes[anchorIndex]
        if not externalNode then
            print("[Gear] 未找到固定传动节点: " .. tostring(anchorIndex))
            return 0
        end
        anchorX = externalNode.x
        anchorY = externalNode.y
        anchorType = externalNode.gearType
        anchorAngle = externalNode.angle or 0
    end

    local anchorRing = GearDefinitions.GetRings(anchorType)[anchorRingName]
    local draggedRing = GearDefinitions.GetRings(gearType)[draggedRingName]
    if not anchorRing or not draggedRing then
        return 0
    end

    return GearSystem.ComputeDrivenAngle(
        anchorAngle,
        math.atan(worldY - anchorY, worldX - anchorX),
        anchorRing.teeth,
        draggedRing.teeth
    )
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
    ) > CONFIG.ShopClickTolerance ^ 2
    if moved then
        shopDrag_.activated = true
    end

    local worldX, worldY = ScreenToWorld(screenX, screenY)
    local definition = GearDefinitions.Get(shopDrag_.gearType)
    local radius = revenueGearRadius_ * definition.radiusScale
    local axleTargetIndex, axleX, axleY =
        GearSystem.FindAxleAssemblyTarget(
            shopDrag_.gearType,
            worldX,
            worldY,
            gameData_.revenueGears,
            -1,
            snapTolerance_
        )

    local previousAxleTargetIndex = shopDrag_.axleTargetIndex
    shopDrag_.axleTargetIndex = axleTargetIndex
    if axleTargetIndex ~= nil then
        local targetGear = gameData_.revenueGears[axleTargetIndex]
        worldX = axleX
        worldY = axleY
        shopDrag_.snapped = false
        shopDrag_.snapAnchorIndex = nil
        shopDrag_.angle = targetGear and targetGear.angle or 0
        shopDrag_.placementValid = shopDrag_.activated
        if previousAxleTargetIndex ~= axleTargetIndex then
            print(string.format(
                "[ShopDrag] 捕获同轴组合: dragged=%s, targetIndex=%d",
                shopDrag_.gearType,
                axleTargetIndex
            ))
        end
    else
        local snappedX,
            snappedY,
            snapped,
            draggedRingName,
            anchorRingName,
            anchorIndex = GearSystem.FindSnapPosition(
            worldX,
            worldY,
            radius,
            gameData_.revenueGears,
            -1,
            mainGearX_,
            mainGearY_,
            mainGearRadius_,
            snapTolerance_,
            shopDrag_.gearType,
            GetFixedTransmissionAnchors()
        )
        worldX = snappedX or worldX
        worldY = snappedY or worldY
        shopDrag_.snapped = snapped == true
        shopDrag_.snapAnchorIndex = anchorIndex
        shopDrag_.angle = shopDrag_.snapped
            and ResolveShopSnapAngle(
                shopDrag_.gearType,
                worldX,
                worldY,
                draggedRingName,
                anchorRingName,
                anchorIndex
            )
            or 0
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
                meshTolerance_,
                GetFixedTransmissionAnchors()
            )
    end

    shopDrag_.worldX = worldX
    shopDrag_.worldY = worldY
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
    if not IsShopGearRevealed(gearType) then
        return
    end
    local logicalX, logicalY = UIToLogical(screenX, screenY)
    screenX = logicalX or screenX
    screenY = logicalY or screenY
    if shopDrag_.gearType ~= nil or activePointerId_ ~= nil then
        return
    end

    local definition = GearDefinitions.Get(gearType)
    if definition.type == "lubricant" then
        local cooldownRemaining = math.max(
            0,
            gameData_.lubricantCooldownRemaining or 0
        )
        if cooldownRemaining > 0 then
            print(string.format(
                "[ShopDrag] 润滑齿轮冷却中，剩余%.1f秒",
                cooldownRemaining
            ))
            return
        end
        if HasActiveLubricantGear() then
            print("[ShopDrag] 已有巡游润滑齿轮正在使用")
            return
        end
    end
    local purchaseCost = GetGearPurchaseCost(definition.type)
    if gameData_.coins < purchaseCost then
        print(string.format(
            "[ShopDrag] 余额不足，可点击查看详情: type=%s, 当前=%d, 需要=%d",
            gearType,
            gameData_.coins,
            purchaseCost
        ))
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
    NotifyTutorial("shop_drag_started", definition.type)
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
        local purchaseCounts = gameData_.gearPurchaseCounts or {}
        gameData_.gearPurchaseCounts = purchaseCounts
        local purchaseCount = purchaseCounts[definition.type] or 0
        local purchaseCost = GearDefinitions.GetPurchaseCost(
            definition.type,
            purchaseCount
        )
        if not shopDrag_.overCanvas or not shopDrag_.placementValid then
            print("[ShopDrag] 放置位置无效，未扣除费用")
        elseif gameData_.coins < purchaseCost then
            print("[ShopDrag] 余额不足，未购买")
        elseif definition.type == "lubricant"
            and (
                (gameData_.lubricantCooldownRemaining or 0) > 0
                or HasActiveLubricantGear()
            ) then
            print("[ShopDrag] 润滑齿轮正在使用或冷却中，未购买")
        else
            local axleTargetIndex = shopDrag_.axleTargetIndex
            gameData_.coins = math.floor(
                gameData_.coins - purchaseCost
            )
            local createdGearIndex = CreateRevenueGearAt(
                gearType,
                "商店拖拽购买",
                shopDrag_.worldX,
                shopDrag_.worldY,
                shopDrag_.angle,
                purchaseCost
            )
            local assembled = false
            if axleTargetIndex ~= nil then
                local smallIndex = gearType == "small"
                        and createdGearIndex
                    or axleTargetIndex
                local largeIndex = gearType == "large"
                        and createdGearIndex
                    or axleTargetIndex
                assembled = AssembleLargeCompound(
                    smallIndex,
                    largeIndex
                )
            end

            if axleTargetIndex == nil then
                purchaseCounts[definition.type] = purchaseCount + 1
                placementGearIndex_ = nil
                selectedGearIndex_ = nil
                RebuildGearNetwork("商店拖拽放置", true)
                RefreshUI()
                MarkSaveDirty(0)
                SaveNow("拖拽购买传动齿轮")
                print(string.format(
                    "[ShopDrag] 购买完成: type=%s, paid=%d, next=%d, position=(%.1f, %.1f)",
                    gearType,
                    purchaseCost,
                    GetGearPurchaseCost(gearType),
                    shopDrag_.worldX,
                    shopDrag_.worldY
                ))
                NotifyTutorial("gear_placed", gearType)
            elseif assembled then
                purchaseCounts[definition.type] = purchaseCount + 1
                RefreshUI()
                MarkSaveDirty(0)
                SaveNow("拖拽购买并组合传动齿轮")
                print(string.format(
                    "[ShopDrag] 购买并组合完成: type=%s, paid=%d, next=%d, targetIndex=%d",
                    gearType,
                    purchaseCost,
                    GetGearPurchaseCost(gearType),
                    axleTargetIndex
                ))
                if gearType == "small" then
                    NotifyTutorial("gear_placed", gearType)
                end
            else
                gameData_.coins = gameData_.coins + purchaseCost
                table.remove(gameData_.revenueGears, createdGearIndex)
                placementGearIndex_ = nil
                selectedGearIndex_ = nil
                RebuildGearNetwork("商店同轴装配失败回退", true)
                RefreshUI()
                print("[ShopDrag] 同轴装配失败，已退回费用")
            end
        end
    elseif gearType ~= nil and not overCanvas then
        ShowShopGearDetails(gearType)
    elseif gearType ~= nil then
        print("[ShopDrag] 画布内松手，不自动打开商品详情")
    end
    ClearShopDragState()
end

---@param pointerId integer
---@param pointerType string
function CancelShopGearDrag(pointerId, pointerType)
    if shopDrag_.pointerId ~= pointerId
        or shopDrag_.pointerType ~= pointerType then
        return
    end
    print("[ShopDrag] 指针取消，未扣除费用")
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
        CloseTransientPopups()
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
        print(string.format("[GearUpgrade] 余额不足: 当前=%d, 需要=%d", gameData_.coins, cost))
        return
    end

    gameData_.coins = gameData_.coins - cost
    local previousLubricationDuration = gear.gearType == "lubricant"
            and GearDefinitions.GetLubricationDuration(gear.level)
        or nil
    gear.level = gear.level + 1
    if previousLubricationDuration then
        local upgradedDuration = GearDefinitions.GetLubricationDuration(
            gear.level
        )
        gear.lubricationRemaining = (gear.lubricationRemaining or 0)
            + math.max(0, upgradedDuration - previousLubricationDuration)
    end
    RebuildGearNetwork("单齿轮升级", true)
    RefreshUI()
    MarkSaveDirty()
    SaveNow("单齿轮升级")

    print(string.format(
        "[GearUpgrade] id=%d, type=%s, level=%d, rpm=%.2f, torque=%.2f",
        gear.id,
        gear.gearType,
        gear.level,
        gear.rpm,
        gear.torque
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

function PurchaseMetaUnlock(category, unlockId)
    if category ~= "buildings" then
        return
    end
    local definition = GearDefinitions.GetMetaUnlock(category, unlockId)
    local owned = gameData_.unlockedBuildings
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
    CloseTransientPopups()
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
    gameData_.lubricantCooldownRemaining = 0
    gameData_.autoDriveUnlocked = false
    gameData_.autoDriveLevel = 0
    gameData_.lastActiveTimestamp = os.time()
    gameData_.savedIncomePerSecond = 0
    gameData_.pendingOfflineCoins = 0
    gameData_.pendingOfflineSeconds = 0
    gameData_.currencyGeneratorProgress = 0
    gameData_.currencyGeneratorLastDirection = 0
    gameData_.miningProgress = 0
    gameData_.miningOre = 0
    gameData_.miningOreInventory = {
        iron = 0,
        copper = 0,
        silver = 0,
        gold = 0,
        crystal = 0,
    }
    gameData_.miningDrillLevel = 1
    gameData_.mainGearTurnProgress = 0
    gameData_.manualClickIncomeRemainder = 0
    gameData_.growthWindowStartTimestamp = os.time()
    gameData_.growthWindowElapsedSeconds = 0
    gameData_.growthWindowStartIncome = 0
    gameData_.ascensionRecommendationShown = false

    selectedGearIndex_ = nil
    placementGearIndex_ = nil
    draggedGearIndex_ = nil
    incomeEffects_.popups = {}
    manualRotationActive_ = 0
    responsiveLayout_.manualMainGearTurnsRemaining = 0
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
        local requiredIncome = GearDefinitions.Ascension.essenceCoinRatio
        local remainingIncome = math.max(
            0,
            requiredIncome - gameData_.runCoinsEarned
        )
        CloseTransientPopups()
        UI.Modal.Alert({
            title = "飞升条件尚未达成",
            message = string.format(
                "飞升只统计本局实际赚取的资金，当前余额不计入。\n本局已赚 ￥%s，还需再赚 ￥%s，达到 ￥%s 后可获得 1 齿轮精华。",
                FormatNumber(gameData_.runCoinsEarned),
                FormatNumber(remainingIncome),
                FormatNumber(requiredIncome)
            ),
            buttonText = "继续经营",
        })
        print(string.format(
            "[Ascension] 条件不足：runCoinsEarned=%d, remaining=%d",
            gameData_.runCoinsEarned,
            remainingIncome
        ))
        return
    end
    CloseTransientPopups()
    UI.Modal.Confirm({
        title = "确认飞升重构",
        message = string.format(
            "本次将获得 %d 齿轮精华。\n本局资金、摆放齿轮和临时等级将全部清空，永久强化与解锁权限保留。",
            reward
        ),
        confirmText = "确认飞升",
        cancelText = "返回检查",
        onConfirm = PerformAscension,
    })
end

function OpenGlobalUpgradePanel()
    CloseTransientPopups("globalUpgrade")
    RefreshGlobalUpgradeUI()
    globalUpgradePanel_:SetVisible(true)
end

local function OpenAscensionPanel()
    CloseTransientPopups("ascension")
    ascensionPanel_:SetVisible(true)
    RefreshUI()
    offlineRewardPanel_:SetVisible(false)
    print(string.format(
        "[Ascension] 面板已打开: reward=%d, runCoinsEarned=%d",
        GearDefinitions.GetAscensionReward(gameData_.runCoinsEarned),
        gameData_.runCoinsEarned
    ))
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
        CloseTransientPopups()
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

    local eligibleEnd = math.min(
        now,
        gameData_.idleEligibleUntil or 0
    )
    local elapsed = math.floor(math.max(
        0,
        eligibleEnd - gameData_.lastActiveTimestamp
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
        "[Offline] 已领取离线收益: +￥%d, 当前余额=￥%d",
        reward,
        gameData_.coins
    ))
end

AssembleLargeCompound = function(smallIndex, largeIndex)
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
    local combinedPurchaseCostPaid = math.max(
        0,
        smallGear.purchaseCostPaid
            or GearDefinitions.Get("small").purchaseCost
    ) + math.max(
        0,
        largeGear.purchaseCostPaid
            or GearDefinitions.Get("large").purchaseCost
    )
    local definition = GearDefinitions.Get("large_compound")
    largeGear.gearType = definition.type
    largeGear.purchaseCostPaid = combinedPurchaseCostPaid > 0
            and combinedPurchaseCostPaid
        or nil
    largeGear.teeth = definition.teeth
    largeGear.radius = revenueGearRadius_ * definition.radiusScale
    UpdateGearNormalizedPosition(largeGear)

    table.remove(gameData_.revenueGears, smallIndex)
    if smallIndex < largeIndex then
        largeIndex = largeIndex - 1
    end

    selectedGearIndex_ = nil
    placementGearIndex_ = nil
    RebuildGearNetwork("大型齿轮同轴装配", true)
    RefreshUI()
    MarkSaveDirty(0)
    SaveNow("大型齿轮同轴装配")
    print(string.format(
        "[AxleAssembly] 装配完成: 消耗小型齿轮 #%d, 大型齿轮 #%d 转换为 32/16 齿同轴复合齿轮",
        smallId,
        largeId
    ))
    return true
end

local function FindGearAt(x, y)
    for index = #gameData_.revenueGears, 1, -1 do
        local gear = gameData_.revenueGears[index]
        local hitRadius = gear.gearType == "lubricant"
                and math.max(gear.radius * 1.8, mainGearRadius_ * 0.24)
            or gear.radius * 1.18
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

function IsClockHelpAt(x, y)
    local helpX, helpY, helpRadius = GearRenderer.GetClockHelpCircle(
        networkState_.clockDisplay
    )
    return DistanceSquared(x, y, helpX, helpY)
        <= (helpRadius * 1.35) ^ 2
end

function IsClockAt(x, y)
    local display = networkState_.clockDisplay
    return math.abs(x - display.x) <= (display.width or 0) * 0.5
        and math.abs(y - display.y) <= (display.height or 0) * 0.5
end

function IsCurrencyGeneratorHelpAt(x, y)
    local helpX, helpY, helpRadius =
        GearRenderer.GetCurrencyGeneratorHelpCircle(
            networkState_.currencyGenerator
        )
    return DistanceSquared(x, y, helpX, helpY)
        <= (helpRadius * 1.35) ^ 2
end

function IsMiningMachineHelpAt(x, y)
    local helpX, helpY, helpRadius =
        GearRenderer.GetMiningMachineHelpCircle(
            networkState_.miningMachine
        )
    return DistanceSquared(x, y, helpX, helpY)
        <= (helpRadius * 1.35) ^ 2
end

function IsCurrencyGeneratorAt(x, y)
    local generator = networkState_.currencyGenerator
    local bodyHalfWidth = math.max(
        generator.bodyWidth or 0,
        generator.imageWidth or 0
    ) * 0.5
    local bodyHalfHeight = math.max(
        generator.bodyHeight or 0,
        generator.imageHeight or 0
    ) * 0.5
    local bodyHit = math.abs(x - (generator.bodyX or generator.x))
            <= bodyHalfWidth
        and math.abs(y - (generator.bodyY or generator.y))
            <= bodyHalfHeight
    local gearHitRadius = (generator.radius or 0) * 1.35
    local gearHit = DistanceSquared(
        x,
        y,
        generator.x,
        generator.y
    ) <= gearHitRadius * gearHitRadius
    return bodyHit or gearHit
end

function IsMiningMachineAt(x, y)
    local machine = networkState_.miningMachine
    local bodyHalfWidth = math.max(
        machine.bodyWidth or 0,
        machine.imageWidth or 0
    ) * 0.5
    local bodyHalfHeight = math.max(
        machine.bodyHeight or 0,
        machine.imageHeight or 0
    ) * 0.5
    local bodyHit = math.abs(x - (machine.bodyX or machine.x))
            <= bodyHalfWidth
        and math.abs(y - (machine.bodyY or machine.y))
            <= bodyHalfHeight
    local gearHitRadius = (machine.radius or 0) * 1.35
    local gearHit = DistanceSquared(
        x,
        y,
        machine.x,
        machine.y
    ) <= gearHitRadius * gearHitRadius
    return bodyHit or gearHit
end

function GetGearRecycleRefund(gear)
    if not gear then
        return 0
    end

    local definition = GearDefinitions.Get(gear.gearType)
    local costBasis = math.max(
        0,
        gear.purchaseCostPaid or definition.purchaseCost or 0
    )
    if gear.gearType == "momma"
        and not gear.purchaseCostPaid then
        costBasis = 0
    elseif gear.gearType == "large_compound"
        and not gear.purchaseCostPaid then
        costBasis = GearDefinitions.Get("small").purchaseCost
            + GearDefinitions.Get("large").purchaseCost
    elseif gear.gearType == "lubricant" then
        local duration = math.max(1, definition.lubricationDuration or 1)
        local remainingRatio = math.max(
            0,
            math.min(1, (gear.lubricationRemaining or 0) / duration)
        )
        costBasis = costBasis * remainingRatio
    end

    if gear.gearType ~= "large_compound" then
        for level = 1, math.max(1, gear.level or 1) - 1 do
            costBasis = costBasis
                + GearDefinitions.GetUpgradeCost(gear.gearType, level)
        end
    end

    return math.max(0, math.floor(costBasis * CONFIG.RecycleRefundRate))
end

function SetRecycleDropZoneVisible(visible, gear)
    local zone = responsiveLayout_.recycleDropZone
    if not zone then
        return
    end
    zone:SetVisible(visible == true)
    responsiveLayout_.recycleHovering = false
    zone:SetStyle({
        backgroundColor = { 176, 36, 39, 238 },
        borderColor = { 255, 129, 102, 255 },
    })
    if visible and responsiveLayout_.recycleRefundLabel then
        responsiveLayout_.recycleRefundLabel:SetText(string.format(
            "松开返还 ￥%s（投入的50%%）",
            FormatNumber(GetGearRecycleRefund(gear))
        ))
    end
end

function ResetRecyclePointerState()
    responsiveLayout_.recycleHoldElapsed = 0
    responsiveLayout_.recycleLongPressArmed = false
    responsiveLayout_.recycleLongPressTriggered = false
    responsiveLayout_.recyclePointerX = 0
    responsiveLayout_.recyclePointerY = 0
    SetRecycleDropZoneVisible(false)
end

function IsRecycleDropZoneAtLogicalPosition(logicalX, logicalY)
    local zone = responsiveLayout_.recycleDropZone
    if not zone or not zone:IsVisible() then
        return false
    end
    local layout = zone:GetAbsoluteLayout()
    if not layout then
        return false
    end
    local logicalPerUI = UI.GetScale() / math.max(dpr_, 0.01)
    local left = layout.x * logicalPerUI
    local top = layout.y * logicalPerUI
    local right = (layout.x + layout.w) * logicalPerUI
    local bottom = (layout.y + layout.h) * logicalPerUI
    return logicalX >= left and logicalX <= right
        and logicalY >= top and logicalY <= bottom
end

function UpdateRecycleHover(logicalX, logicalY)
    if not responsiveLayout_.recycleLongPressTriggered then
        return
    end
    local hovering = IsRecycleDropZoneAtLogicalPosition(logicalX, logicalY)
    if hovering == responsiveLayout_.recycleHovering then
        return
    end
    responsiveLayout_.recycleHovering = hovering
    responsiveLayout_.recycleDropZone:SetStyle({
        backgroundColor = hovering
                and { 224, 52, 44, 252 }
            or { 176, 36, 39, 238 },
        borderColor = hovering
                and { 255, 236, 174, 255 }
            or { 255, 129, 102, 255 },
    })
end

function UpdateRecycleLongPress(timeStep)
    if not responsiveLayout_.recycleLongPressArmed
        or responsiveLayout_.recycleLongPressTriggered
        or activePointerId_ == nil
        or draggedGearIndex_ == nil
        or pinchActive_ then
        return
    end
    responsiveLayout_.recycleHoldElapsed =
        responsiveLayout_.recycleHoldElapsed + timeStep
    if responsiveLayout_.recycleHoldElapsed
        < CONFIG.RecycleLongPressSeconds then
        return
    end

    responsiveLayout_.recycleLongPressArmed = false
    responsiveLayout_.recycleLongPressTriggered = true
    dragActivated_ = true
    local gear = GetRevenueGear(draggedGearIndex_)
    SetRecycleDropZoneVisible(true, gear)
    print(string.format(
        "[Recycle] 长按激活: gearId=%d, refund=%d",
        gear.id,
        GetGearRecycleRefund(gear)
    ))
end

function RecycleDraggedGear()
    local index = draggedGearIndex_
    local gear = index and gameData_.revenueGears[index] or nil
    if not gear then
        return false
    end
    local refund = GetGearRecycleRefund(gear)
    local gearId = gear.id
    local gearType = gear.gearType
    table.remove(gameData_.revenueGears, index)
    gameData_.coins = gameData_.coins + refund
    selectedGearIndex_ = nil
    placementGearIndex_ = nil
    RebuildGearNetwork("回收齿轮", true)
    RefreshUI()
    MarkSaveDirty(0)
    SaveNow("回收齿轮")
    print(string.format(
        "[Recycle] 回收完成: id=%d, type=%s, refund=%d, coins=%d",
        gearId,
        gearType,
        refund,
        gameData_.coins
    ))
    return true
end

function DeleteSelectedGear()
    local index = selectedGearIndex_
    local gear = index and gameData_.revenueGears[index] or nil
    if not gear then
        selectedGearIndex_ = nil
        RefreshSelectedGearUI()
        return false
    end

    local refund = GetGearRecycleRefund(gear)
    local gearId = gear.id
    local gearType = gear.gearType
    table.remove(gameData_.revenueGears, index)
    gameData_.coins = gameData_.coins + refund
    selectedGearIndex_ = nil
    placementGearIndex_ = nil
    gearDetailsPanel_:SetVisible(false)
    RebuildGearNetwork("详情删除齿轮", true)
    RefreshUI()
    MarkSaveDirty(0)
    SaveNow("详情删除齿轮")
    print(string.format(
        "[Recycle] 详情删除完成: id=%d, type=%s, refund=%d, coins=%d",
        gearId,
        gearType,
        refund,
        gameData_.coins
    ))
    return true
end

function ClearPointerState()
    activePointerId_ = nil
    activePointerType_ = nil
    draggedGearIndex_ = nil
    dragActivated_ = false
    dragPlacementValid_ = true
    dragSnapValid_ = false
    dragSnapRing_ = nil
    dragAnchorRing_ = nil
    axleAssembly_.smallIndex = nil
    axleAssembly_.largeIndex = nil
    canvasPanning_ = false
    pointerStartedOnMainGear_ = false
    responsiveLayout_.pointerObject = nil
    pointerMoved_ = false
    ResetRecyclePointerState()
end

local function BeginCanvasPointer(pointerId, pointerType, screenX, screenY)
    if activePointerId_ ~= nil or pinchActive_ then
        return
    end

    if responsiveLayout_.IsFaultIndicatorAt(screenX, screenY) then
        responsiveLayout_.FocusFaultIndicator()
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
    responsiveLayout_.pointerObject = nil
    if gearIndex == nil then
        if IsClockHelpAt(worldX, worldY) then
            responsiveLayout_.pointerObject = "clockHelp"
        elseif IsCurrencyGeneratorHelpAt(worldX, worldY) then
            responsiveLayout_.pointerObject = "currencyGeneratorHelp"
        elseif IsMiningMachineHelpAt(worldX, worldY) then
            responsiveLayout_.pointerObject = "miningMachineHelp"
        elseif IsClockAt(worldX, worldY) then
            responsiveLayout_.pointerObject = "clock"
        elseif IsCurrencyGeneratorAt(worldX, worldY) then
            responsiveLayout_.pointerObject = "currencyGenerator"
        elseif IsMiningMachineAt(worldX, worldY) then
            responsiveLayout_.pointerObject = "miningMachine"
        end
    end
    pointerMoved_ = enteringPlacement
    dragActivated_ = enteringPlacement
    canvasPanning_ = false
    pointerStartX_ = screenX
    pointerStartY_ = screenY
    pointerLastX_ = screenX
    pointerLastY_ = screenY
    ResetRecyclePointerState()

    if gearIndex then
        local gear = GetRevenueGear(gearIndex)
        dragOffsetX_ = gear.x - worldX
        dragOffsetY_ = gear.y - worldY
        dragOriginalX_ = gear.x
        dragOriginalY_ = gear.y
        if not enteringPlacement then
            responsiveLayout_.recycleLongPressArmed = true
            responsiveLayout_.recyclePointerX = screenX
            responsiveLayout_.recyclePointerY = screenY
            print(string.format(
                "[Recycle] 长按候选: gearId=%d, threshold=%.2fs",
                gear.id,
                CONFIG.RecycleLongPressSeconds
            ))
        end
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
        if responsiveLayout_.recycleLongPressArmed then
            responsiveLayout_.recycleLongPressArmed = false
            responsiveLayout_.recycleHoldElapsed = 0
        end
    end
    responsiveLayout_.recyclePointerX = screenX
    responsiveLayout_.recyclePointerY = screenY

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

    if responsiveLayout_.recycleLongPressTriggered then
        UpdateRecycleHover(screenX, screenY)
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

    axleAssembly_.smallIndex = nil
    axleAssembly_.largeIndex = nil
    if axleTargetIndex ~= nil then
        local targetGear = gameData_.revenueGears[axleTargetIndex]
        if gear.gearType == "small"
            and targetGear
            and targetGear.gearType == "large" then
            axleAssembly_.smallIndex = draggedGearIndex_
            axleAssembly_.largeIndex = axleTargetIndex
        elseif gear.gearType == "large"
            and targetGear
            and targetGear.gearType == "small" then
            axleAssembly_.smallIndex = axleTargetIndex
            axleAssembly_.largeIndex = draggedGearIndex_
        else
            axleTargetIndex = nil
        end
    end
    if axleAssembly_.smallIndex ~= nil
        and axleAssembly_.largeIndex ~= nil then
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
            gear.gearType,
            GetFixedTransmissionAnchors()
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
            meshTolerance_,
            GetFixedTransmissionAnchors()
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

        if responsiveLayout_.recycleLongPressTriggered
            and IsRecycleDropZoneAtLogicalPosition(x, y) then
            RecycleDraggedGear()
            ClearPointerState()
            return
        end

        if dragActivated_
            and axleAssembly_.smallIndex ~= nil
            and axleAssembly_.largeIndex ~= nil then
            local assembled = AssembleLargeCompound(
                axleAssembly_.smallIndex,
                axleAssembly_.largeIndex
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
            print("[Input] 已选中画布齿轮并打开详情 id=" .. tostring(gearId))
        end
    elseif (responsiveLayout_.pointerObject == "clockHelp"
            or responsiveLayout_.pointerObject == "clock")
        and not pointerMoved_ then
        selectedGearIndex_ = nil
        RefreshSelectedGearUI()
        ShowClockDetails()
    elseif (responsiveLayout_.pointerObject == "currencyGeneratorHelp"
            or responsiveLayout_.pointerObject == "currencyGenerator")
        and not pointerMoved_ then
        selectedGearIndex_ = nil
        RefreshSelectedGearUI()
        ShowCurrencyGeneratorDetails()
    elseif (responsiveLayout_.pointerObject == "miningMachineHelp"
            or responsiveLayout_.pointerObject == "miningMachine")
        and not pointerMoved_ then
        selectedGearIndex_ = nil
        RefreshSelectedGearUI()
        ShowMiningMachineDetails()
    elseif pointerStartedOnMainGear_ and not pointerMoved_ then
        if not networkState_.jammed
            and not networkState_.overloaded then
            CreditManualMainGearClick()
            responsiveLayout_.manualMainGearTurnsRemaining =
                responsiveLayout_.manualMainGearTurnsRemaining + 1
            manualRotationActive_ = 1
            StartGearAudioPlayback()
            print(string.format(
                "[Input] 主齿轮点击立即结算，追加1圈快速旋转，待转圈数=%.2f",
                responsiveLayout_.manualMainGearTurnsRemaining
            ))
        end
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

function IsAscensionOpenButtonAtUIPosition(uiX, uiY)
    local target = UI.FindWidgetAt(uiX, uiY)
    while target do
        if target.id == "ascensionOpenButton"
            or target.id == "landscapeAscensionButton" then
            return true
        end
        target = target.parent
    end

    if responsiveLayout_.mode == "landscape" then
        local button = responsiveLayout_.landscapeAscensionButton
        if button and button:IsVisible() then
            local layout = button:GetAbsoluteLayout()
            local hitPadding = 10
            if uiX >= layout.x - hitPadding
                and uiX <= layout.x + layout.w + hitPadding
                and uiY >= layout.y - hitPadding
                and uiY <= layout.y + layout.h + hitPadding then
                return true
            end
        end

        local screenWidth = responsiveLayout_.screenUIWidth or 0
        local screenHeight = responsiveLayout_.screenUIHeight or 0
        local rightInset = math.max(8, math.min(16, screenWidth * 0.01))
        local buttonWidth = math.max(84, math.min(96, screenWidth * 0.06))
        local buttonHeight = math.max(34, math.min(42, screenHeight * 0.052))
        local topHudHeight = math.max(58, math.min(76, screenHeight * 0.095))
        local buttonTop = (topHudHeight - buttonHeight) * 0.5
        local hitPadding = 10
        return uiX >= screenWidth - rightInset - buttonWidth - hitPadding
            and uiX <= screenWidth - rightInset + hitPadding
            and uiY >= buttonTop - hitPadding
            and uiY <= buttonTop + buttonHeight + hitPadding
    end

    return false
end

function IsTutorialPointAllowed(uiX, uiY)
    local tutorial = responsiveLayout_.tutorial
    return tutorial == nil or tutorial:IsPointAllowed(uiX, uiY)
end

function HandleMouseButtonDown(eventType, eventData)
    if responsiveLayout_.homeVisible then
        return
    end
    if eventData:GetInt("Button") ~= MOUSEB_LEFT then
        return
    end
    local uiScale = math.max(UI.GetScale(), 0.01)
    local uiX = eventData:GetInt("X") / uiScale
    local uiY = eventData:GetInt("Y") / uiScale
    local layoutX, layoutY = ScreenUIToLayoutUI(uiX, uiY)
    if not IsTutorialPointAllowed(layoutX, layoutY) then
        print("[Tutorial] 已阻止目标区域外的鼠标操作")
        return
    end
    if IsAscensionOpenButtonAtUIPosition(uiX, uiY) then
        ClearShopDragState()
        print("[Input] 原生鼠标命中飞升入口")
        OpenAscensionPanel()
        return
    end
    if shopDrag_.gearType ~= nil then
        return
    end
    local gearType = FindShopGearTypeAtUIPosition(uiX, uiY)
    if gearType then
        local layoutX, layoutY = ScreenUIToLayoutUI(uiX, uiY)
        BeginShopGearDrag(gearType, 0, "mouse", layoutX, layoutY)
    end
end

function HandleTouchBegin(eventType, eventData)
    if responsiveLayout_.homeVisible then
        return
    end
    local uiScale = math.max(UI.GetScale(), 0.01)
    local uiX = eventData:GetInt("X") / uiScale
    local uiY = eventData:GetInt("Y") / uiScale
    local layoutX, layoutY = ScreenUIToLayoutUI(uiX, uiY)
    if not IsTutorialPointAllowed(layoutX, layoutY) then
        print("[Tutorial] 已阻止目标区域外的触摸操作")
        return
    end
    if IsAscensionOpenButtonAtUIPosition(uiX, uiY) then
        ClearShopDragState()
        print("[Input] 原生触摸命中飞升入口")
        OpenAscensionPanel()
        return
    end
    if shopDrag_.gearType ~= nil then
        return
    end
    local gearType = FindShopGearTypeAtUIPosition(uiX, uiY)
    if gearType then
        local layoutX, layoutY = ScreenUIToLayoutUI(uiX, uiY)
        BeginShopGearDrag(
            gearType,
            eventData:GetInt("TouchID"),
            "touch",
            layoutX,
            layoutY
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

responsiveLayout_.Toggle = function()
    if responsiveLayout_.homeVisible then
        return
    end
    if responsiveLayout_.mode ~= "landscape" then
        responsiveLayout_.mode = "landscape"
        graphics:SetOrientations("LandscapeLeft LandscapeRight")
        if responsiveLayout_.rebuild then
            responsiveLayout_.rebuild()
        else
            RefreshLayout()
        end
    end
    print("[Layout] 已切换为横屏工厂布局")
end

function InitializeGearAudio()
    responsiveLayout_.audioSystem = GetAudio()
    if not responsiveLayout_.audioSystem:IsInitialized() then
        responsiveLayout_.audioModeReady = responsiveLayout_.audioSystem:SetMode(
            100,
            48000,
            true,
            true
        )
        print(string.format(
            "[GearAudio] 音频设备初始化: ready=%s, initialized=%s",
            tostring(responsiveLayout_.audioModeReady),
            tostring(responsiveLayout_.audioSystem:IsInitialized())
        ))
    end
    if responsiveLayout_.audioSystem:IsInitialized() then
        responsiveLayout_.audioSystem:SetMasterGain(SOUND_MASTER, 1.0)
        responsiveLayout_.audioSystem:SetMasterGain(SOUND_EFFECT, 1.0)
        if not responsiveLayout_.audioSystem:IsPlaying() then
            responsiveLayout_.audioSystem:Play()
        end
    else
        print("[GearAudio] WARNING: 音频设备不可用，齿轮声音不会输出")
    end

    local sound = cache:GetResource(
        "Sound",
        "audio/sfx/gear_toy_ratchet_loud_continuous.mp3"
    )
    if not sound then
        print("[GearAudio] ERROR: 齿轮循环音效加载失败")
        return
    end

    sound:SetLooped(true)
    local audioScene = Scene()
    local audioNode = audioScene:CreateChild("GearAudio")
    ---@type SoundSource
    local source = audioNode:CreateComponent("SoundSource")
    source:SetSoundType(SOUND_EFFECT)
    source:SetDeclickEnabled(true)

    local baseFrequency = math.max(sound:GetFrequency(), 1)

    responsiveLayout_.gearAudioScene = audioScene
    responsiveLayout_.gearAudioSource = source
    responsiveLayout_.gearAudioSound = sound
    responsiveLayout_.gearAudioBaseFrequency = baseFrequency
    responsiveLayout_.gearAudioFrequency = baseFrequency
    responsiveLayout_.gearAudioGain = 0
    print(string.format(
        "[GearAudio] 循环音效就绪: frequency=%dHz, waitingForRotation=true",
        baseFrequency
    ))
end

function StartGearAudioPlayback()
    local source = responsiveLayout_.gearAudioSource
    local sound = responsiveLayout_.gearAudioSound
    if not source or not sound then
        return
    end

    local audioSystem = responsiveLayout_.audioSystem or GetAudio()
    responsiveLayout_.audioSystem = audioSystem
    if not audioSystem:IsInitialized() then
        responsiveLayout_.audioModeReady = audioSystem:SetMode(
            100,
            48000,
            true,
            true
        )
    end
    if audioSystem:IsInitialized() then
        audioSystem:SetMasterGain(SOUND_MASTER, 1.0)
        audioSystem:SetMasterGain(SOUND_EFFECT, 1.0)
        if not audioSystem:IsPlaying() then
            audioSystem:Play()
        end
    end

    if not source:IsPlaying() then
        local startGain = math.max(
            responsiveLayout_.gearAudioGain,
            0.82
        )
        responsiveLayout_.gearAudioGain = startGain
        source:Play(
            sound,
            responsiveLayout_.gearAudioFrequency,
            startGain
        )
        print(string.format(
            "[GearAudio] 转动开始，启动循环音效: audioReady=%s, gain=%.2f",
            tostring(audioSystem:IsInitialized()),
            startGain
        ))
    end
end

function StopGearAudioPlayback(reason)
    responsiveLayout_.gearAudioGain = 0
    local source = responsiveLayout_.gearAudioSource
    if source and source:IsPlaying() then
        source:StopImmediate()
        if reason then
            print("[GearAudio] 已停止循环音效: " .. reason)
        end
    end
end

function UpdateGearAudio(timeStep)
    local source = responsiveLayout_.gearAudioSource
    if not source then
        return
    end

    if responsiveLayout_.homeVisible then
        StopGearAudioPlayback("首页静音")
        return
    end

    local blocked = networkState_.jammed or networkState_.overloaded
    local manualRunning = manualRotationActive_ > 0
    local automaticRunning = gameData_.autoDriveUnlocked
        and not blocked
        and GetMainRPM() > 0

    local running = not blocked
        and (manualRunning or automaticRunning)
    if not running then
        responsiveLayout_.gearAudioGain = 0
        if source:IsPlaying() then
            source:StopImmediate()
        end
        return
    end

    StartGearAudioPlayback()
    if not source:IsPlaying() then
        return
    end

    local audibleRPM = automaticRunning
            and GetMainRPM()
        or 0
    for _, gear in ipairs(gameData_.revenueGears) do
        if gear.connected and not gear.jammed and not gear.overloaded then
            audibleRPM = math.max(audibleRPM, gear.rpm or 0)
        end
    end
    if manualRunning then
        audibleRPM = math.max(audibleRPM, 150)
    end

    local rpmFactor = math.min(
        1,
        math.log(1 + math.max(0, audibleRPM)) / math.log(181)
    )
    local pitchMultiplier = (0.78 + rpmFactor * 0.50) * 0.68
    local targetFrequency = responsiveLayout_.gearAudioBaseFrequency
        * pitchMultiplier

    local loadRatio = math.min(
        1,
        math.max(0, networkState_.totalLoad or 0)
            / math.max(
                GearDefinitions.Main.torquePerLevel,
                networkState_.sourceTorque or 0
            )
    )
    local targetGain = math.min(
        1.0,
        0.82
            + math.min(connectedGearCount_, 8) * 0.05
            + loadRatio * 0.12
    )

    local gainBlend = 1 - math.exp(-math.max(0, timeStep) * 6)
    responsiveLayout_.gearAudioGain = responsiveLayout_.gearAudioGain
        + (targetGain - responsiveLayout_.gearAudioGain) * gainBlend

    local frequencyBlend = 1
        - math.exp(-math.max(0, timeStep) * 4)
    responsiveLayout_.gearAudioFrequency =
        responsiveLayout_.gearAudioFrequency
            + (
                targetFrequency
                - responsiveLayout_.gearAudioFrequency
            ) * frequencyBlend

    source:SetGain(responsiveLayout_.gearAudioGain)
    source:SetFrequency(responsiveLayout_.gearAudioFrequency)
end

function ShutdownGearAudio()
    local source = responsiveLayout_.gearAudioSource
    if source then
        source:StopImmediate()
    end
    local audioScene = responsiveLayout_.gearAudioScene
    if audioScene then
        audioScene:Dispose()
    end
    responsiveLayout_.gearAudioScene = nil
    responsiveLayout_.gearAudioSource = nil
    responsiveLayout_.gearAudioSound = nil
    responsiveLayout_.gearAudioBaseFrequency = 0
    responsiveLayout_.gearAudioFrequency = 0
    responsiveLayout_.gearAudioGain = 0
end

NotifyTutorial = function(action, value)
    local tutorial = responsiveLayout_.tutorial
    if tutorial then
        tutorial:Notify(action, value)
    end
end

local function CompleteTutorial(skipped)
    gameData_.tutorialVersion = TutorialRuntime.Version
    gameData_.tutorialStep = "completed"
    gameData_.tutorialCompleted = true
    MarkSaveDirty(0)
    SaveNow(skipped and "跳过新手教程" or "完成新手教程")
end

function CompleteLubricantTutorial(skipped)
    gameData_.lubricantTutorialCompleted = true
    gameData_.lubricantTutorialStep = "completed"
    responsiveLayout_.tutorial = nil
    MarkSaveDirty(0)
    SaveNow(skipped and "跳过润滑教程" or "完成润滑教程")
    print(skipped
        and "[Tutorial] 玩家跳过润滑补充教程"
        or "[Tutorial] 润滑补充教程完成，传动已恢复")
end

function BuildTutorialContext()
    local refs = responsiveLayout_.tutorialRefs or {}
    local uiToLogical = UI.GetScale() / math.max(dpr_, 1)
    local mainScreenX = mainGearX_ * canvasScale_ + canvasOffsetX_
    local mainScreenY = mainGearY_ * canvasScale_ + canvasOffsetY_
    local mainScreenRadius = mainGearRadius_ * canvasScale_
    local mainGearRect = {
        x = mainScreenX / uiToLogical - mainScreenRadius / uiToLogical,
        y = mainScreenY / uiToLogical - mainScreenRadius / uiToLogical,
        w = mainScreenRadius * 2 / uiToLogical,
        h = mainScreenRadius * 2 / uiToLogical,
    }
    local dropCenterX = mainScreenX + mainScreenRadius * 2.04
    local dropCenterY = mainScreenY
    local dropRadius = mainScreenRadius * 0.72
    local lubricantDropRadius = mainScreenRadius * 0.52
    local hasSmallGear = false
    for _, gear in ipairs(gameData_.revenueGears) do
        if gear.gearType == "small" then
            hasSmallGear = true
            break
        end
    end
    return {
        homeVisible = responsiveLayout_.homeVisible,
        screenWidth = responsiveLayout_.screenUIWidth,
        screenHeight = responsiveLayout_.screenUIHeight,
        coins = gameData_.coins,
        lifetimeCoins = gameData_.lifetimeCoinsEarned,
        lubricantCost = GetGearPurchaseCost("lubricant"),
        mainTorqueLevel = gameData_.mainTorqueLevel,
        hasSmallGear = hasSmallGear,
        mainGearRect = mainGearRect,
        mainGearDropRect = {
            x = (dropCenterX - dropRadius) / uiToLogical,
            y = (dropCenterY - dropRadius) / uiToLogical,
            w = dropRadius * 2 / uiToLogical,
            h = dropRadius * 2 / uiToLogical,
        },
        lubricantDropRect = {
            x = mainGearRect.x + mainGearRect.w * 0.24,
            y = mainGearRect.y + mainGearRect.h * 0.24,
            w = lubricantDropRadius * 2 / uiToLogical,
            h = lubricantDropRadius * 2 / uiToLogical,
        },
        currencyGeneratorRect = {
            x = (networkState_.currencyGenerator.bodyX
                    - networkState_.currencyGenerator.bodyWidth * 0.5)
                / uiToLogical,
            y = (networkState_.currencyGenerator.bodyY
                    - networkState_.currencyGenerator.bodyHeight * 0.5)
                / uiToLogical,
            w = networkState_.currencyGenerator.bodyWidth / uiToLogical,
            h = networkState_.currencyGenerator.bodyHeight / uiToLogical,
        },
        rightRailExpandButton = refs.rightRailExpandButton,
        leftRailExpandButton = refs.leftRailExpandButton,
        torqueUpgradeButton = mainTorqueUpgradeButton_,
        upgradeConfirmButton = responsiveLayout_.clickUpgradeConfirmButton,
        smallGearButton = buySmallGearButton_,
        lubricantGearButton = responsiveLayout_.buyLubricantGearButton,
    }
end

CreateLubricantTutorialController = function()
    local tutorial = responsiveLayout_.tutorial
    if tutorial and tutorial:IsActive() then
        return
    end
    if tutorial and not tutorial:IsActive() then
        responsiveLayout_.tutorial = nil
    end
    local root = responsiveLayout_.tutorialRoot
    if not root
        or root ~= uiRoot_
        or responsiveLayout_.homeVisible
        or gameData_.tutorialCompleted ~= true
        or gameData_.lubricantTutorialCompleted == true
        or not networkState_.maintenanceJammed then
        return
    end

    local lubricantUnlocked =
        gameData_.permanentContentUnlocks ~= nil
        and gameData_.permanentContentUnlocks["gear:lubricant"] == true
    if lubricantUnlocked or gameData_.coins >= GetGearPurchaseCost("lubricant") then
        return
    end

    local tutorial = TutorialRuntime.Create({
        kind = "lubricant",
        completed = false,
        initialStep = gameData_.lubricantTutorialStep
                or TutorialRuntime.LubricantFirstStep,
        getContext = BuildTutorialContext,
        onStepChanged = function(step)
            gameData_.lubricantTutorialStep = step
            MarkSaveDirty(0)
        end,
        onComplete = CompleteLubricantTutorial,
    })
    responsiveLayout_.tutorial = tutorial
    root:AddChild(tutorial.layer_)
    print(string.format(
        "[Tutorial] 检测到缺油卡壳，启动润滑补充教程: coins=%d cost=%d",
        gameData_.coins,
        GetGearPurchaseCost("lubricant")
    ))
end

local function CreateTutorialController(root)
    responsiveLayout_.tutorialRoot = root
    CloseTransientPopups()
    if offlineRewardPanel_ then
        offlineRewardPanel_:SetVisible(false)
    end
    local currentVersionCompleted = gameData_.tutorialCompleted == true
        and gameData_.tutorialVersion >= TutorialRuntime.Version
    print(string.format(
        "[Tutorial] 创建检查: savedVersion=%d currentVersion=%d completed=%s currentCompleted=%s step=%s",
        gameData_.tutorialVersion or 0,
        TutorialRuntime.Version,
        tostring(gameData_.tutorialCompleted),
        tostring(currentVersionCompleted),
        tostring(gameData_.tutorialStep)
    ))
    if currentVersionCompleted then
        responsiveLayout_.tutorial = nil
        print("[Tutorial] 当前版本基础教程已完成，等待按需触发补充教程")
        return
    end

    gameData_.tutorialVersion = TutorialRuntime.Version
    gameData_.tutorialStep = TutorialRuntime.FirstStep
    gameData_.tutorialCompleted = false
    MarkSaveDirty(0)

    local tutorial = TutorialRuntime.Create({
        completed = false,
        initialStep = gameData_.tutorialStep
                or TutorialRuntime.FirstStep,
        getContext = BuildTutorialContext,
        onStepChanged = function(step)
            gameData_.tutorialVersion = TutorialRuntime.Version
            gameData_.tutorialStep = step
            MarkSaveDirty(0)
        end,
        onComplete = CompleteTutorial,
    })
    responsiveLayout_.tutorial = tutorial
    root:AddChild(tutorial.layer_)
    print(string.format(
        "[Tutorial] 教程层已挂载: active=%s rootChildren=%d",
        tostring(tutorial:IsActive()),
        root:GetNumChildren()
    ))
end

responsiveLayout_.ResetTutorialTestAccountData = function()
    gameData_ = SaveSystem.CreateNewGameData()
    gameData_.idleAdDayKey = GetIdleDayKey(os.time())
    gameData_.lastActiveTimestamp = os.time()
    mainGearAngle_ = 0
    manualRotationActive_ = 0
    responsiveLayout_.manualMainGearTurnsRemaining = 0
    selectedGearIndex_ = nil
    placementGearIndex_ = nil
    canvasScale_ = 1
    canvasOffsetX_ = 0
    canvasOffsetY_ = 0
    connectedGearCount_ = 0
    totalIncomePerSecond_ = 0
    connections_ = {}
    saveDirty_ = false
    saveTimer_ = 0
    SaveSystem.Save(gameData_)

    if clientCloud ~= nil then
        local resetSnapshot = MetaProgression.CreateResetSnapshot()
        clientCloud:Set(MetaProgression.CloudKey, resetSnapshot, {
            ok = function()
                print("[TutorialTest] 云端永久进度已重置")
            end,
            error = function(code, reason)
                print(string.format(
                    "[TutorialTest] 云端永久进度重置失败 code=%s reason=%s",
                    tostring(code),
                    tostring(reason)
                ))
            end,
            timeout = function()
                print("[TutorialTest] 云端永久进度重置超时")
            end,
        })
    end
    print("[TutorialTest] 测试账号已恢复为全新玩家")
end

responsiveLayout_.CheckTutorialTestAccount = function(onReady)
    TutorialRuntime.CheckTestAccount(
        clientCloud,
        CONFIG.TutorialTestAccountKey,
        responsiveLayout_,
        onReady
    )
end

responsiveLayout_.CreateUI = nil

responsiveLayout_.ContinueInitialLoading = function(isTutorialTestAccount)
    if isTutorialTestAccount then
        responsiveLayout_.ResetTutorialTestAccountData()
    end
    responsiveLayout_.CreateUI()
    AccumulateOfflineReward(os.time())
    AccumulateMommaFactory(os.time())
    RefreshUI()
    if not isTutorialTestAccount then
        LoadMetaFromCloud()
    else
        cloudMetaLoaded_ = true
    end
    RefreshHomeAssetDisplay()
    SyncIncomeLeaderboard(true)
    print("[Loading] 全部素材已加载，进入游戏首页")
end

responsiveLayout_.FinishInitialLoading = function()
    responsiveLayout_.loadingActive = false
    InitializeGearAudio()
    if not responsiveLayout_.loadingRendererInitialized then
        GearRenderer.Initialize(vg_)
        responsiveLayout_.loadingRendererInitialized = true
    end
    if TutorialRuntime.IsWebPreview() then
        responsiveLayout_.tutorialTestAccount = true
        responsiveLayout_.tutorialTestAccountChecked = true
        print("[TutorialTest] Web 浏览器预览，自动按新手账号重置")
        responsiveLayout_.ContinueInitialLoading(true)
    else
        responsiveLayout_.CheckTutorialTestAccount(
            responsiveLayout_.ContinueInitialLoading
        )
    end
end

responsiveLayout_.CreateUI = function()
    local uiScale = math.max(UI.GetScale(), 0.01)
    local screenUIWidth = graphics:GetWidth() / uiScale
    local screenUIHeight = graphics:GetHeight() / uiScale
    local rotatePortrait = responsiveLayout_.mode == "portrait"
        and graphics:GetWidth() >= graphics:GetHeight()
    local layoutUIWidth = rotatePortrait
            and screenUIHeight
        or screenUIWidth
    local layoutUIHeight = rotatePortrait
            and screenUIWidth
        or screenUIHeight
    responsiveLayout_.screenUIWidth = screenUIWidth
    responsiveLayout_.screenUIHeight = screenUIHeight
    responsiveLayout_.rotatePortrait = rotatePortrait

    if responsiveLayout_.homeVisible then
        -- 首页是独立 UI 根，但排行榜仍需基于当前存档重建一次
        -- 齿轮网络，确保上传的是实时每秒收益而不是初始值 0。
        RefreshLayout()
        local homeUI = HomeUI.Create({
            visible = true,
            assetText = "￥" .. FormatNumber(gameData_.lifetimeCoinsEarned),
            layoutWidth = layoutUIWidth,
            layoutHeight = layoutUIHeight,
            rotatePortrait = rotatePortrait,
            onEnterFactory = EnterGearFactory,
            onOpenLeaderboard = function()
                SyncIncomeLeaderboard(true)
            end,
        })
        UI.SetRoot(homeUI.overlay)
        responsiveLayout_.homeUI = homeUI
        responsiveLayout_.apply = nil
        if #responsiveLayout_.homeLeaderboardEntries > 0 then
            ApplyHomeLeaderboard(responsiveLayout_.homeLeaderboardEntries)
            SetHomeLeaderboardStatus(string.format(
                "前%d名",
                #responsiveLayout_.homeLeaderboardEntries
            ))
        elseif clientCloud == nil then
            homeUI.setLeaderboardStatus("云端排行榜暂不可用")
        else
            homeUI.setLeaderboardStatus("正在同步云端排行榜…")
        end
        print("[UI] 独立首页根节点已启用")
        return
    end

    local refs = GameUI.Create({
        title = CONFIG.Title,
        layoutMode = responsiveLayout_.mode,
        rotatePortrait = rotatePortrait,
        layoutWidth = layoutUIWidth,
        layoutHeight = layoutUIHeight,
        toggleLayoutMode = responsiveLayout_.Toggle,
        returnHome = ReturnToHome,
        preparePopupOpen = CloseTransientPopups,
        openGlobalUpgradePanel = OpenGlobalUpgradePanel,
        upgradeClickValue = UpgradeClickValue,
        getMainUpgradeDetails = function(upgradeType)
            if upgradeType == "torque" then
                local currentTorque = GetMainTorque()
                local nextTorque = GearDefinitions.GetMainTorque(
                    gameData_.mainTorqueLevel + 1
                )
                local cost = GearDefinitions.GetMainUpgradeCost(
                    "torque",
                    gameData_.mainTorqueLevel
                )
                return {
                    titleText = "给主齿轮力量",
                    descriptionText = string.format(
                        "• 每次升级增加%s扭矩，首次升级解锁自动运转",
                        FormatNumber(GearDefinitions.Main.torquePerLevel)
                    ),
                    currentText = string.format(
                        "• 当前总扭矩 %s（Lv.%d）",
                        FormatNumber(currentTorque),
                        gameData_.mainTorqueLevel
                    ),
                    resultText = string.format(
                        "• 升级后总扭矩 %s",
                        FormatNumber(nextTorque)
                    ),
                    buttonText = string.format(
                        "升级  ￥%s",
                        FormatNumber(cost)
                    ),
                    canUpgrade = gameData_.coins
                            >= GearDefinitions.TorqueUpgradeUnlockCoins
                        and gameData_.coins >= cost,
                }
            end

            if upgradeType == "circleIncome" then
                local currentIncome = GetMainCircleIncome()
                local nextIncome = GearDefinitions.GetMainCircleIncome(
                    gameData_.mainCircleIncomeLevel + 1
                )
                local cost = GearDefinitions.GetMainUpgradeCost(
                    "circleIncome",
                    gameData_.mainCircleIncomeLevel
                )
                return {
                    titleText = "单个中央主齿轮收益",
                    descriptionText = "• 升级对象仅为画布中央这一个主齿轮。每级只增加它完成一整圈时获得的金币；其他传动齿轮、货币生成器和矿机均不受影响。",
                    currentText = string.format(
                        "• 中央主齿轮当前每圈收益 ￥%s（Lv.%d）",
                        FormatNumber(currentIncome),
                        gameData_.mainCircleIncomeLevel
                    ),
                    resultText = string.format(
                        "• 升级后中央主齿轮每圈收益 ￥%s",
                        FormatNumber(nextIncome)
                    ),
                    buttonText = string.format(
                        "升级  ￥%s",
                        FormatNumber(cost)
                    ),
                    canUpgrade = gameData_.coins >= cost,
                }
            end

            local currentClickValue = GetClickValue()
            local nextClickValue = math.min(
                GearDefinitions.Main.manualClickMax,
                currentClickValue * GearDefinitions.Main.manualClickGrowth
            )
            local cost = GetUpgradeCost()
            local reachedMax = currentClickValue
                >= GearDefinitions.Main.manualClickMax
            return {
                titleText = "点击收益",
                descriptionText = "• 每次点击主齿轮都会立即获得金币，并追加一整圈快速旋转动画。每级使点击收益增加30%。",
                currentText = string.format(
                    "• 当前每次点击立即获得￥%s（Lv.%d）",
                    FormatCurrency(currentClickValue),
                    gameData_.clickLevel
                ),
                resultText = string.format(
                    "• 升级后每次点击立即获得￥%s",
                    FormatCurrency(nextClickValue)
                ),
                buttonText = reachedMax
                        and "已达上限"
                    or string.format("升级  ￥%s", FormatNumber(cost)),
                canUpgrade = not reachedMax and gameData_.coins >= cost,
            }
        end,
        shopGearDragStart = BeginShopGearDrag,
        shopGearDragMove = MoveShopGearDrag,
        shopGearDragEnd = EndShopGearDrag,
        shopGearDragCancel = CancelShopGearDrag,
        tutorialNotify = NotifyTutorial,
        showAutoDriveRequirement = ShowAutoDriveRequirement,
        openIdleEarnings = OpenIdleEarnings,
        upgradeMainTorque = UpgradeMainTorque,
        upgradeMainCircleIncome = UpgradeMainCircleIncome,
        upgradeSelectedGear = UpgradeSelectedGear,
        deleteSelectedGear = DeleteSelectedGear,
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
        fixedMachinePrimaryAction = function()
            if responsiveLayout_.selectedFixedMachine == "miningMachine" then
                DeliverMiningOre()
            end
        end,
        fixedMachineSecondaryAction = function()
            if responsiveLayout_.selectedFixedMachine == "miningMachine" then
                UpgradeMiningDrill()
            end
        end,
        canvasPointerDown = HandleCanvasPointerDown,
        canvasPointerMove = HandleCanvasPointerMove,
        canvasPointerUp = HandleCanvasPointerUp,
        canvasPointerCancel = HandleCanvasPointerCancel,
    })

    local homeUI = HomeUI.Create({
        visible = responsiveLayout_.homeVisible,
        assetText = "￥" .. FormatNumber(gameData_.lifetimeCoinsEarned),
        layoutWidth = layoutUIWidth,
        layoutHeight = layoutUIHeight,
        rotatePortrait = rotatePortrait,
        onEnterFactory = EnterGearFactory,
        onOpenLeaderboard = function()
            SyncIncomeLeaderboard(true)
        end,
    })
    refs.root:AddChild(homeUI.overlay)
    responsiveLayout_.homeUI = homeUI
    if responsiveLayout_.homeVisible then
        if clientCloud == nil then
            homeUI.setLeaderboardStatus("云端排行榜暂不可用")
        else
            homeUI.setLeaderboardStatus("正在同步云端前100名…")
        end
    end

    uiRoot_, coinLabel_, clickValueLabel_, revenueLabel_, levelLabel_, shopInfoLabel_ =
        refs.root, refs.coinLabel, refs.clickValueLabel, refs.revenueLabel, refs.levelLabel, refs.shopInfoLabel
    responsiveLayout_.apply = refs.applyResponsiveLayout
    responsiveLayout_.idleEarningsButton = refs.idleEarningsButton
    essenceLabel_, powerStatusLabel_, loadGaugeLabel_, loadProgressBar_ =
        refs.essenceLabel, refs.powerStatusLabel, refs.loadGaugeLabel, refs.loadProgressBar
    upgradeButton_, mainTorqueUpgradeButton_, mainCircleIncomeUpgradeButton_ =
        refs.upgradeButton, refs.mainTorqueUpgradeButton, refs.mainCircleIncomeUpgradeButton
    responsiveLayout_.clickUpgradeConfirmButton =
        refs.clickUpgradeConfirmButton
    responsiveLayout_.clickUpgradeResultLabel = refs.clickUpgradeResultLabel
    responsiveLayout_.refreshMainUpgradeDetails =
        refs.refreshMainUpgradeDetails
    responsiveLayout_.hideMainUpgradeDetails =
        refs.hideMainUpgradeDetails
    responsiveLayout_.setUpgradeRailUnlocked = refs.setUpgradeRailUnlocked
    responsiveLayout_.setPermanentUpgradeRevealed =
        refs.setPermanentUpgradeRevealed
    responsiveLayout_.setGearWarehouseUnlocked =
        refs.setGearWarehouseUnlocked
    responsiveLayout_.setShopGearRevealed = refs.setShopGearRevealed
    buySmallGearButton_, buySmallGearPriceLabel_, buyMediumGearButton_, buyMediumGearPriceLabel_ =
        refs.buySmallGearButton, refs.buySmallGearPriceLabel, refs.buyMediumGearButton, refs.buyMediumGearPriceLabel
    buyLargeGearButton_, buyLargeGearPriceLabel_, buyCompoundGearButton_, buyCompoundGearPriceLabel_, autoDriveButton_ =
        refs.buyLargeGearButton, refs.buyLargeGearPriceLabel, refs.buyCompoundGearButton, refs.buyCompoundGearPriceLabel, refs.autoDriveButton
    buyMommaGearButton_, buyMommaGearPriceLabel_, factoryStatusLabel_, factoryClaimButton_ =
        refs.buyMommaGearButton, refs.buyMommaGearPriceLabel, refs.factoryStatusLabel, refs.factoryClaimButton
    responsiveLayout_.buyLubricantGearButton = refs.buyLubricantGearButton
    responsiveLayout_.buyLubricantGearPriceLabel =
        refs.buyLubricantGearPriceLabel
    responsiveLayout_.buyCoinGearButton = refs.buyCoinGearButton
    responsiveLayout_.buyCoinGearPriceLabel = refs.buyCoinGearPriceLabel
    gearDetailsPanel_, gearDetailsTitleLabel_, gearDetailsStatusLabel_, gearDetailsStatsLabel_, gearDetailsUpgradeLabel_ =
        refs.gearDetailsPanel, refs.gearDetailsTitleLabel, refs.gearDetailsStatusLabel, refs.gearDetailsStatsLabel, refs.gearDetailsUpgradeLabel
    gearDetailsEssenceLabel_ = refs.gearDetailsEssenceLabel
    gearUpgradeButton_, gearDetailsCloseButton_ = refs.gearUpgradeButton, refs.gearDetailsCloseButton
    responsiveLayout_.gearDeleteButton = refs.gearDeleteButton
    shopDrag_.detailsPanel = refs.shopGearDetailsPanel
    shopDrag_.detailsTitle = refs.shopGearDetailsTitleLabel
    shopDrag_.detailsPrice = refs.shopGearDetailsPriceLabel
    shopDrag_.detailsDescription = refs.shopGearDetailsDescriptionLabel
    shopDrag_.generatorDetailsPanel = refs.currencyGeneratorDetailsPanel
    shopDrag_.generatorDetailsTitle = refs.currencyGeneratorDetailsTitleLabel
    shopDrag_.generatorDetailsStatus = refs.currencyGeneratorDetailsStatusLabel
    shopDrag_.generatorDetailsDescription = refs.currencyGeneratorDetailsDescriptionLabel
    shopDrag_.generatorDetailsPrimaryButton =
        refs.currencyGeneratorDetailsPrimaryButton
    shopDrag_.generatorDetailsSecondaryButton =
        refs.currencyGeneratorDetailsSecondaryButton
    shopDrag_.generatorDetailsActionDock =
        refs.currencyGeneratorDetailsActionDock
    globalUpgradePanel_, globalUpgradeSummaryLabel_, globalIncomeUpgradeButton_, decayUpgradeButton_, offlineUpgradeButton_ =
        refs.globalUpgradePanel, refs.globalUpgradeSummaryLabel, refs.globalIncomeUpgradeButton, refs.decayUpgradeButton, refs.offlineUpgradeButton
    globalUpgradeOpenButton_, globalUpgradeCloseButton_ = refs.globalUpgradeOpenButton, refs.globalUpgradeCloseButton
    responsiveLayout_.permanentUpgradeLevelLabel = refs.permanentUpgradeLevelLabel
    unlockBuildingButton_ = refs.unlockBuildingButton
    ascensionPanel_, ascensionOpenButton_, ascensionRewardLabel_, ascensionProgressLabel_ =
        refs.ascensionPanel, refs.ascensionOpenButton, refs.ascensionRewardLabel, refs.ascensionProgressLabel
    responsiveLayout_.landscapeAscensionButton = refs.landscapeAscensionButton
    responsiveLayout_.homeReturnButton = refs.homeReturnButton
    ascensionConfirmButton_, ascensionToastLabel_ = refs.ascensionConfirmButton, refs.ascensionToastLabel
    offlineRewardPanel_, offlineRewardLabel_, claimOfflineButton_, canvasInputArea_ =
        refs.offlineRewardPanel, refs.offlineRewardLabel, refs.claimOfflineButton, refs.canvasInputArea
    responsiveLayout_.tutorialRefs = {
        rightRailExpandButton = refs.rightRailExpandButton,
        leftRailExpandButton = refs.leftRailExpandButton,
    }
    responsiveLayout_.recycleDropZone = refs.recycleDropZone
    responsiveLayout_.recycleRefundLabel = refs.recycleRefundLabel

    RefreshLayout()
    RefreshUI()
    CreateTutorialController(refs.root)
    if networkState_.maintenanceJammed
        and CreateLubricantTutorialController then
        CreateLubricantTutorialController()
    end
end

responsiveLayout_.rebuild = function()
    if activePointerId_ ~= nil and CancelCanvasPointer then
        CancelCanvasPointer(activePointerId_, activePointerType_)
    end
    responsiveLayout_.apply = nil
    selectedGearIndex_ = nil
    ClearShopDragState()
    ClearPointerState()
    responsiveLayout_.CreateUI()
end

function Start()
    graphics.windowTitle = CONFIG.Title
    responsiveLayout_.mode = "landscape"
    input.mouseMode = MM_ABSOLUTE
    input.mouseVisible = true
    math.randomseed(os.time())

    print("[Game] 开始初始化 " .. CONFIG.Title)
    responsiveLayout_.homeVisible = true
    responsiveLayout_.homeLeaderboardLoading = false
    responsiveLayout_.homeLeaderboardRequestId =
        responsiveLayout_.homeLeaderboardRequestId + 1
    responsiveLayout_.homeAssetText = ""
    responsiveLayout_.incomeLeaderboardWritePending = false
    responsiveLayout_.incomeLeaderboardDirty = true
    responsiveLayout_.lastIncomeLeaderboardValue = -1
    responsiveLayout_.incomeLeaderboardSyncTimer = 0
    graphics:SetOrientations("LandscapeLeft LandscapeRight")
    ---@type GearWorkshopGameData
    local loadedData = SaveSystem.Load()
    gameData_ = loadedData
    gameData_.gearPurchaseCounts = gameData_.gearPurchaseCounts or {}
    mainGearAngle_ = math.max(
        0,
        math.min(0.999999, gameData_.mainGearTurnProgress or 0)
    ) * math.pi * 2
    gameData_.miningProgress = gameData_.miningProgress or 0
    gameData_.miningOre = gameData_.miningOre or 0
    if type(gameData_.miningOreInventory) ~= "table" then
        gameData_.miningOreInventory = {
            iron = gameData_.miningOre,
            copper = 0,
            silver = 0,
            gold = 0,
            crystal = 0,
        }
        print(string.format(
            "[MiningMachine] 旧矿石库存已迁移为铁矿石: %d",
            gameData_.miningOre
        ))
    end
    responsiveLayout_.NormalizeMiningInventory()
    gameData_.miningDrillLevel = gameData_.miningDrillLevel or 1
    gameData_.idleAdDayKey = gameData_.idleAdDayKey or 0
    gameData_.idleAdWatchCount = math.max(
        0,
        math.min(2, gameData_.idleAdWatchCount or 0)
    )
    gameData_.idleEligibleUntil = math.max(
        0,
        gameData_.idleEligibleUntil or 0
    )
    RefreshIdleAdDay(os.time())
    gameData_.lubricantCooldownRemaining = math.max(
        0,
        gameData_.lubricantCooldownRemaining or 0
    )
    local geometryMigrated = GearGeometryMigration.Migrate(gameData_)
    if geometryMigrated then
        MarkSaveDirty(0)
        print("[Game] 已迁移旧存档齿轮网络到新尺寸体系")
    end

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
        gear.lubricationRemaining = math.max(
            0,
            gear.lubricationRemaining
                or (
                    definition.type == "lubricant"
                        and GearDefinitions.GetLubricationDuration(
                            gear.level
                        )
                )
                or definition.lubricationDuration
                or GearDefinitions.DefaultLubricationDuration
        )
        gear.lubricated = false
        gear.lubricationSource = false
        gear.maintenanceJammed = false
        gear.autonomous = definition.type == "lubricant"
        gear.patrolTargetCursor = math.max(1, gear.patrolTargetCursor or 1)
        gear.patrolState = gear.patrolState or "travel"
        gear.patrolOrbitAngle = gear.patrolOrbitAngle or 0
        gear.patrolOrbitTravel = gear.patrolOrbitTravel or 0
        gear.oilEffectRemaining = 0
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

    UI.Init({
        theme = GameUI.Theme,
        scale = UI.Scale.DEFAULT,
    })

    local loadingState = responsiveLayout_
    loadingState.loadingActive = true
    loadingState.loadingElapsed = 0
    loadingState.loadingAssetIndex = 1
    loadingState.loadingAssetRetries = 0
    LoadingScreen.Start({
        ui = UI,
        imageCache = ImageCache,
        onComplete = responsiveLayout_.FinishInitialLoading,
    })

    SubscribeToEvent(vg_, "NanoVGRender", "HandleNanoVGRender")
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("ScreenMode", "HandleScreenMode")
    SubscribeToEvent("OrientationChanged", "HandleOrientationChanged")
    SubscribeToEvent("MouseButtonDown", "HandleMouseButtonDown")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("TouchBegin", "HandleTouchBegin")
    SubscribeToEvent("MouseMove", "HandleMouseMove")
    SubscribeToEvent("MouseWheel", "HandleMouseWheel")
    SubscribeToEvent("MouseButtonUp", "HandleMouseButtonUp")
    SubscribeToEvent("TouchMove", "HandleTouchMove")
    SubscribeToEvent("TouchEnd", "HandleTouchEnd")
    SubscribeToEvent("AppWillEnterBackground", "HandleAppBackground")
    SubscribeToEvent("AppDidEnterBackground", "HandleAppBackground")
    SubscribeToEvent("AppWillEnterForeground", "HandleAppForeground")
    SubscribeToEvent("ExitRequested", "HandleExitRequested")

    print("[Game] 初始化完成，等待购买并摆放传动齿轮")
end

function RegisterTutorialTestAccount()
    if clientCloud == nil then
        print("[TutorialTest] 当前环境无 clientCloud，无法登记测试账号")
        return
    end
    clientCloud:Set(CONFIG.TutorialTestAccountKey, true, {
        ok = function()
            print(string.format(
                "[TutorialTest] 当前账号已登记: userId=%s",
                tostring(clientCloud.userId)
            ))
            responsiveLayout_.ResetTutorialTestAccountData()
            responsiveLayout_.homeVisible = true
            responsiveLayout_.tutorial = nil
            if responsiveLayout_.rebuild then
                responsiveLayout_.rebuild()
            end
        end,
        error = function(code, reason)
            print(string.format(
                "[TutorialTest] 登记失败 code=%s reason=%s",
                tostring(code),
                tostring(reason)
            ))
        end,
        timeout = function()
            print("[TutorialTest] 登记测试账号超时")
        end,
    })
end

function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    if key == KEY_F9 then
        RegisterTutorialTestAccount()
    end
end

function Stop()
    print("[Game] 正在停止")
    MarkSaveDirty(0)
    SaveNow("游戏停止")
    ShutdownGearAudio()
    UI.Shutdown()
    nvgDelete(vg_)
end

function UpdateLubricantPatrol(gear, timeStep)
    local definition = GearDefinitions.Get("lubricant")
    local speedMultiplier = GearDefinitions.GetLubricantSpeedMultiplier(
        gear.level
    )
    if (gear.lubricationRemaining or 0) <= 0 then
        gear.rpm = 0
        return
    end

    local targets = {
        { x = mainGearX_, y = mainGearY_, radius = mainGearRadius_ },
    }
    for _, targetGear in ipairs(gameData_.revenueGears) do
        if targetGear.gearType ~= "lubricant" then
            targets[#targets + 1] = targetGear
        end
    end
    local targetCount = #targets
    gear.patrolTargetCursor = math.max(
        1,
        math.min(targetCount, gear.patrolTargetCursor or 1)
    )
    local target = targets[gear.patrolTargetCursor]
    local orbitRadius = target.radius + gear.radius * 1.15
    local dx = target.x - gear.x
    local dy = target.y - gear.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local travelSpeed = math.max(
        mainGearRadius_ * definition.patrolSpeedScale,
        gear.radius * 8
    ) * speedMultiplier

    if gear.patrolState ~= "orbit" then
        if distance <= orbitRadius + travelSpeed * timeStep then
            gear.patrolState = "orbit"
            gear.patrolOrbitAngle = math.atan(
                gear.y - target.y,
                gear.x - target.x
            )
            gear.patrolOrbitTravel = 0
        elseif distance > 0.001 then
            local step = math.min(distance - orbitRadius, travelSpeed * timeStep)
            gear.x = gear.x + dx / distance * step
            gear.y = gear.y + dy / distance * step
        end
    end

    if gear.patrolState == "orbit" then
        local orbitSeconds = math.max(
            0.2,
            definition.patrolOrbitSeconds / speedMultiplier
        )
        local angularStep = math.pi * 2 * timeStep / orbitSeconds
        gear.patrolOrbitAngle = (gear.patrolOrbitAngle + angularStep)
            % (math.pi * 2)
        gear.patrolOrbitTravel = (gear.patrolOrbitTravel or 0) + angularStep
        gear.x = target.x + math.cos(gear.patrolOrbitAngle) * orbitRadius
        gear.y = target.y + math.sin(gear.patrolOrbitAngle) * orbitRadius
        if target.gearType ~= nil then
            target.oilEffectRemaining = definition.oilEffectDuration
        else
            responsiveLayout_.mainOilEffectRemaining = definition.oilEffectDuration
        end
        if gear.patrolOrbitTravel >= math.pi * 2 then
            gear.patrolTargetCursor = gear.patrolTargetCursor % targetCount + 1
            gear.patrolState = "travel"
            gear.patrolOrbitTravel = 0
        end
    end

    local autonomousRPM = definition.autonomousRPM * speedMultiplier
    gear.angle = (gear.angle or 0)
        + timeStep * autonomousRPM * math.pi * 2 / 60
    gear.rpm = autonomousRPM
    gear.spinDirection = 1
end

function UpdateMiningMachine(timeStep)
    local machine = networkState_.miningMachine
    local generator = networkState_.powerGeneratorInterface
    local definition = GearDefinitions.MiningMachine
    local step = math.min(math.max(timeStep, 0), 0.25)
    machine.electricPowered = generator.generating == true
    machine.powered = machine.electricPowered
    local generatorRPM = generator.electricalRPM or generator.rpm or 0
    local generatorTorque = generator.torque or 0
    machine.generatorRPM = generatorRPM
    machine.generatorTorque = generatorTorque
    machine.rpm = machine.electricPowered and generatorRPM or 0
    machine.torque = machine.electricPowered
            and generatorTorque
        or 0
    machine.spinDirection = machine.electricPowered
            and (generator.spinDirection or 0)
        or 0
    machine.status = not machine.electricPowered and (
            generator.status == "jammed" and "jammed"
            or generator.status == "overloaded" and "overloaded"
            or generator.status == "insufficientTorque"
                and "insufficientTorque"
            or "powerOff"
        )
        or machine.torque < definition.requiredTorque
            and "insufficientTorque"
        or machine.rpm < definition.minRPM
            and "insufficientRPM"
        or machine.rpm > definition.maxRPM
            and "overspeed"
        or "running"
    machine.rewardFlash = math.max(
        0,
        (machine.rewardFlash or 0) - timeStep * 2.5
    )
    machine.miningEfficiency = GetMiningEfficiency(machine)

    if machine.powered
        and (machine.rpm or 0) > 0
        and (machine.spinDirection or 0) ~= 0 then
        machine.animationTime = (machine.animationTime or 0) + step
        machine.angle = (machine.angle or 0)
            + machine.rpm
                * step
                * math.pi
                * 2
                / 60
                * machine.spinDirection
    end

    if machine.miningEfficiency <= 0 then
        return
    end

    local drill = definition.drillLevels[gameData_.miningDrillLevel]
    gameData_.miningProgress = gameData_.miningProgress
        + step * machine.miningEfficiency / drill.cycleSeconds
    local completedCycles = math.floor(gameData_.miningProgress)
    if completedCycles <= 0 then
        MarkSaveDirty(CONFIG.IncomeSaveDelay)
        return
    end

    gameData_.miningProgress = gameData_.miningProgress - completedCycles
    local availableSpace = math.max(
        0,
        definition.maxOre - responsiveLayout_.NormalizeMiningInventory()
    )
    local producedOre = math.min(
        availableSpace,
        completedCycles * drill.orePerCycle
    )
    if producedOre <= 0 then
        gameData_.miningProgress = 0
        return
    end

    local oreTotal = responsiveLayout_.AddRandomMiningOre(producedOre)
    if oreTotal >= definition.maxOre then
        gameData_.miningProgress = 0
    end
    machine.rewardFlash = 1
    incomeEffects_.SpawnPopup(
        machine.x,
        machine.y,
        machine.radius,
        producedOre,
        "矿石 +" .. tostring(producedOre)
    )
    print(string.format(
        "[MiningMachine] 完成%d轮钻进，产出%d矿石，库存=%d/%d，效率=%.0f%%",
        completedCycles,
        producedOre,
        oreTotal,
        definition.maxOre,
        machine.miningEfficiency * 100
    ))
    RefreshUI()
    MarkSaveDirty(0)
end

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local timeStep = eventData:GetFloat("TimeStep")
    if input:GetKeyPress(KEY_F9) then
        print("[TutorialTest] 检测到 F9，登记当前账号并重置")
        RegisterTutorialTestAccount()
    end
    if responsiveLayout_.loadingActive then
        LoadingScreen.Update(timeStep)
        return
    end
    RefreshHomeAssetDisplay()
    if responsiveLayout_.incomeLeaderboardDirty then
        responsiveLayout_.incomeLeaderboardSyncTimer =
            responsiveLayout_.incomeLeaderboardSyncTimer - timeStep
        if responsiveLayout_.incomeLeaderboardSyncTimer <= 0 then
            responsiveLayout_.incomeLeaderboardSyncTimer =
                CONFIG.IncomeLeaderboardSyncDelay
            SyncIncomeLeaderboard(false)
        end
    end
    local clockInterface = networkState_.clockInterface
    local clockDisplay = networkState_.clockDisplay
    local clockStep = math.min(math.max(timeStep, 0), 0.25)
    local clockRunning = clockInterface.powered == true
        and clockInterface.connected == true
        and not networkState_.jammed
        and not networkState_.overloaded
        and (clockInterface.rpm or 0) > 0
        and (clockInterface.spinDirection or 0) ~= 0
    if clockRunning then
        clockDisplay.animationTime = (clockDisplay.animationTime or 0)
            + clockStep
        clockInterface.angle = (clockInterface.angle or 0)
            + clockInterface.rpm
                * clockStep
                * math.pi
                * 2
                / 60
                * clockInterface.spinDirection
    elseif clockDisplay.running == true then
        clockDisplay.animationTime = 0
    end
    clockInterface.running = clockRunning
    clockDisplay.running = clockRunning
    UpdateRecycleLongPress(timeStep)
    warningPhase_ = warningPhase_ + timeStep
    if (gameData_.lubricantCooldownRemaining or 0) > 0 then
        gameData_.lubricantCooldownRemaining = math.max(
            0,
            gameData_.lubricantCooldownRemaining - timeStep
        )
        local cooldownDisplaySecond = math.ceil(
            gameData_.lubricantCooldownRemaining
        )
        if cooldownDisplaySecond
            ~= responsiveLayout_.lubricantCooldownDisplaySecond then
            responsiveLayout_.lubricantCooldownDisplaySecond =
                cooldownDisplaySecond
            RefreshUI()
        end
        if gameData_.lubricantCooldownRemaining <= 0 then
            print("[Lubrication] 润滑齿轮冷却结束，可再次使用")
            MarkSaveDirty(0)
            SaveNow("润滑齿轮冷却结束")
        else
            MarkSaveDirty(CONFIG.IncomeSaveDelay)
        end
    end
    responsiveLayout_.mainOilEffectRemaining = 0
    for _, gear in ipairs(gameData_.revenueGears) do
        gear.oilEffectRemaining = 0
    end
    local powerGeneratorInterface = networkState_.powerGeneratorInterface
    local powerGeneratorDisplay = networkState_.powerGeneratorDisplay
    local powerGeneratorStep = math.min(math.max(timeStep, 0), 0.25)
    local interfaceVisualRPM = powerGeneratorInterface.rpm or 0
    local interfaceParent = type(powerGeneratorInterface.parentIndex) == "number"
        and gameData_.revenueGears[powerGeneratorInterface.parentIndex]
        or nil
    if interfaceParent then
        local parentRPM = interfaceParent.rpm or 0
        if manualRotationActive_ > 0 and parentRPM <= 0 then
            parentRPM = GetMainRPM() * (interfaceParent.rpmRatio or 0)
        end
        for _, connection in ipairs(connections_) do
            if (connection.a == powerGeneratorInterface.parentIndex
                    and connection.b == powerGeneratorInterface.id)
                or (connection.b == powerGeneratorInterface.parentIndex
                    and connection.a == powerGeneratorInterface.id) then
                local parentTeeth = connection.a
                        == powerGeneratorInterface.parentIndex
                        and connection.aTeeth
                    or connection.bTeeth
                local interfaceTeeth = connection.a
                        == powerGeneratorInterface.id
                        and connection.aTeeth
                    or connection.bTeeth
                interfaceVisualRPM = parentRPM
                    * parentTeeth
                    / math.max(1, interfaceTeeth)
                break
            end
        end
    end
    local automaticGeneratorMotion = gameData_.autoDriveUnlocked
        and powerGeneratorInterface.connected
        and not networkState_.jammed
        and not networkState_.overloaded
        and powerGeneratorInterface.spinDirection ~= 0
        and interfaceVisualRPM > 0
    local manualGeneratorMotion = manualRotationActive_ > 0
        and powerGeneratorInterface.connected
        and not networkState_.jammed
        and not networkState_.overloaded
        and powerGeneratorInterface.spinDirection ~= 0
        and interfaceVisualRPM > 0
    local powerGeneratorMechanicallyRotating = automaticGeneratorMotion
        or manualGeneratorMotion
    if powerGeneratorMechanicallyRotating then
        powerGeneratorDisplay.animationTime =
            (powerGeneratorDisplay.animationTime or 0) + powerGeneratorStep
        powerGeneratorInterface.angle =
            (powerGeneratorInterface.angle or 0)
                + interfaceVisualRPM
                    * powerGeneratorStep
                    * math.pi
                    * 2
                    / 60
                    * powerGeneratorInterface.spinDirection
    end
    local powerGeneratorRunning =
        powerGeneratorMechanicallyRotating
            and powerGeneratorInterface.assetUnlocked ~= false
            and (powerGeneratorInterface.torque or 0)
                >= GearDefinitions.MiningMachine.requiredTorque
    powerGeneratorInterface.mechanicallyRotating =
        powerGeneratorMechanicallyRotating
    powerGeneratorInterface.generating = powerGeneratorRunning
    powerGeneratorInterface.electricalRPM = interfaceVisualRPM
    powerGeneratorDisplay.mechanicallyRotating =
        powerGeneratorMechanicallyRotating
    powerGeneratorDisplay.powered = powerGeneratorRunning
    powerGeneratorDisplay.status = powerGeneratorInterface.status
    powerGeneratorDisplay.rpm = interfaceVisualRPM
    powerGeneratorDisplay.spinDirection = powerGeneratorInterface.spinDirection
    powerGeneratorDisplay.gearAngle = powerGeneratorInterface.angle or 0
    gameData_.growthWindowElapsedSeconds =
        gameData_.growthWindowElapsedSeconds + timeStep
    local drivetrainRunning = gameData_.autoDriveUnlocked
        and not networkState_.jammed
        and not networkState_.overloaded
    local manualDrivetrainRunning = manualRotationActive_ > 0
        and not networkState_.jammed
        and not networkState_.overloaded
    local lubricationStateChanged = false
    local expiredLubricantIndex = nil
    for gearIndex, gear in ipairs(gameData_.revenueGears) do
        if gear.gearType == "lubricant" then
            if (gear.lubricationRemaining or 0) <= 0 then
                expiredLubricantIndex = gearIndex
                lubricationStateChanged = true
            elseif gear.id == networkState_.lubricationSourceGearId then
                UpdateLubricantPatrol(gear, timeStep)
                local previousRemaining = gear.lubricationRemaining or 0
                gear.lubricationRemaining = math.max(
                    0,
                    previousRemaining - timeStep
                )
                if previousRemaining > 0
                    and gear.lubricationRemaining <= 0 then
                    expiredLubricantIndex = gearIndex
                    lubricationStateChanged = true
                end
            end
        elseif (drivetrainRunning or manualDrivetrainRunning)
            and gear.meshed
            and not networkState_.lubricationActive then
            local previousRemaining = gear.lubricationRemaining or 0
            gear.lubricationRemaining = math.max(
                0,
                previousRemaining - timeStep
            )
            lubricationStateChanged = lubricationStateChanged
                or (
                    previousRemaining > 0
                    and gear.lubricationRemaining <= 0
                )
        end
    end
    if expiredLubricantIndex then
        local expiredGear = gameData_.revenueGears[expiredLubricantIndex]
        table.remove(gameData_.revenueGears, expiredLubricantIndex)
        if selectedGearIndex_ == expiredLubricantIndex then
            selectedGearIndex_ = nil
        elseif selectedGearIndex_ and selectedGearIndex_ > expiredLubricantIndex then
            selectedGearIndex_ = selectedGearIndex_ - 1
        end
        if placementGearIndex_ == expiredLubricantIndex then
            placementGearIndex_ = nil
        elseif placementGearIndex_ and placementGearIndex_ > expiredLubricantIndex then
            placementGearIndex_ = placementGearIndex_ - 1
        end
        if draggedGearIndex_ == expiredLubricantIndex then
            draggedGearIndex_ = nil
            dragActivated_ = false
        elseif draggedGearIndex_ and draggedGearIndex_ > expiredLubricantIndex then
            draggedGearIndex_ = draggedGearIndex_ - 1
        end
        gameData_.lubricantCooldownRemaining = math.max(
            gameData_.lubricantCooldownRemaining or 0,
            GearDefinitions.Get("lubricant").cooldownSeconds
        )
        print(string.format(
            "[Lubrication] 巡游润滑齿轮#%d有效期耗尽，已从画布移除并进入%.0f秒冷却",
            expiredGear.id,
            gameData_.lubricantCooldownRemaining
        ))
        RebuildGearNetwork("巡游润滑齿轮耗尽并消失", true)
        RefreshUI()
        MarkSaveDirty(0)
        SaveNow("巡游润滑齿轮耗尽并消失")
    elseif lubricationStateChanged then
        print("[Lubrication] 普通齿轮润滑耗尽，重新计算卡壳状态")
        RebuildGearNetwork("普通齿轮润滑耗尽", true)
        RefreshUI()
        MarkSaveDirty(0)
    end
    if networkState_.lubricationActive
        or drivetrainRunning
        or manualDrivetrainRunning then
        responsiveLayout_.lubricationUIRefreshTimer =
            responsiveLayout_.lubricationUIRefreshTimer - timeStep
        if not lubricationStateChanged
            and responsiveLayout_.lubricationUIRefreshTimer <= 0 then
            responsiveLayout_.lubricationUIRefreshTimer = 1
            RefreshSelectedGearUI()
            MarkSaveDirty(CONFIG.IncomeSaveDelay)
        end
    end
    if drivetrainRunning then
        local mainTurnsThisFrame = timeStep * GetMainRPM() / 60
        mainGearAngle_ = mainGearAngle_
            + mainTurnsThisFrame * math.pi * 2
        gameData_.mainGearTurnProgress =
            gameData_.mainGearTurnProgress + mainTurnsThisFrame
        local automaticMainTurns = math.floor(
            gameData_.mainGearTurnProgress
        )
        if automaticMainTurns > 0 then
            gameData_.mainGearTurnProgress =
                gameData_.mainGearTurnProgress - automaticMainTurns
            local reward = CreditCoins(
                GetMainCircleIncome()
                    * GearDefinitions.GetGlobalIncomeMultiplier(
                        gameData_.globalIncomeLevel
                    )
                    * GetMainGearIncomeMultiplier()
                    * automaticMainTurns
            )
            incomeEffects_.SpawnPopup(
                mainGearX_,
                mainGearY_,
                mainGearRadius_,
                reward
            )
            print(string.format(
                "[Economy] 自动主齿轮完成%d圈: +￥%d",
                automaticMainTurns,
                reward
            ))
            RefreshUI()
            MarkSaveDirty()
        else
            MarkSaveDirty(CONFIG.IncomeSaveDelay)
        end
    end
    if responsiveLayout_.manualMainGearTurnsRemaining > 0 then
        if not networkState_.jammed and not networkState_.overloaded then
            local plannedManualTurns = timeStep * 3.0
            local manualTurns = math.min(
                plannedManualTurns,
                responsiveLayout_.manualMainGearTurnsRemaining
            )
            local manualStep = manualTurns * math.pi * 2
            mainGearAngle_ = mainGearAngle_ + manualStep
            responsiveLayout_.manualMainGearTurnsRemaining =
                responsiveLayout_.manualMainGearTurnsRemaining - manualTurns
            if responsiveLayout_.manualMainGearTurnsRemaining <= 0.000001 then
                responsiveLayout_.manualMainGearTurnsRemaining = 0
                manualRotationActive_ = 0
                print("[Input] 主齿轮快速旋转动画完成")
            else
                manualRotationActive_ = 1
            end
            if manualTurns > 0 then
                for gearIndex, gear in ipairs(gameData_.revenueGears) do
                    if gear.meshed and (gear.rpmRatio or 0) > 0 then
                        local gearTurns = manualTurns * gear.rpmRatio
                        gear.angle = gear.angle
                            + gearTurns
                                * math.pi
                                * 2
                                * gear.spinDirection
                        if gear.gearType == "coin" then
                            gear.turnProgress = (gear.turnProgress or 0)
                                + gearTurns
                            local completedTurns = math.floor(
                                gear.turnProgress
                            )
                            if completedTurns > 0 then
                                gear.turnProgress = gear.turnProgress
                                    - completedTurns
                                local definition = GearDefinitions.Get("coin")
                                local reward = CreditCoins(
                                    definition.baseRewardPerTurn
                                        * GetGlobalIncomeMultiplier()
                                        * GetClockIncomeMultiplierForGearIndex(
                                            gearIndex
                                        )
                                        * completedTurns
                                )
                                incomeEffects_.SpawnPopup(
                                    gear.x,
                                    gear.y,
                                    gear.radius,
                                    reward
                                )
                                print(string.format(
                                    "[CoinGear] 手动传动带动金币齿轮#%d完成%d圈: +￥%d",
                                    gear.id,
                                    completedTurns,
                                    reward
                                ))
                                RefreshUI()
                                MarkSaveDirty()
                            else
                                MarkSaveDirty(CONFIG.IncomeSaveDelay)
                            end
                        end
                    end
                end
            end
        else
            manualRotationActive_ = 1
        end
    else
        manualRotationActive_ = 0
    end
    mainGearPulse_ = math.max(0, mainGearPulse_ - timeStep * 4.8)
    UpdateGearAudio(timeStep)

    for index = #incomeEffects_.popups, 1, -1 do
        local popup = incomeEffects_.popups[index]
        popup.age = popup.age + timeStep
        if popup.age >= popup.duration then
            table.remove(incomeEffects_.popups, index)
        end
    end

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

    for gearIndex, gear in ipairs(gameData_.revenueGears) do
        if gear.gearType ~= "lubricant"
            and gear.connected
            and gear.rpm > 0
            and gear.spinDirection ~= 0 then
            local turnsThisFrame = gear.rpm * timeStep / 60
            gear.angle = gear.angle
                + turnsThisFrame * math.pi * 2 * gear.spinDirection
            if gear.gearType == "coin" then
                gear.turnProgress = (gear.turnProgress or 0)
                    + turnsThisFrame
                local completedTurns = math.floor(gear.turnProgress)
                if completedTurns > 0 then
                    gear.turnProgress = gear.turnProgress - completedTurns
                    local definition = GearDefinitions.Get("coin")
                    local reward = CreditCoins(
                        definition.baseRewardPerTurn
                            * GetGlobalIncomeMultiplier()
                            * GetClockIncomeMultiplierForGearIndex(gearIndex)
                            * completedTurns
                    )
                    incomeEffects_.SpawnPopup(
                        gear.x,
                        gear.y,
                        gear.radius,
                        reward
                    )
                    print(string.format(
                        "[CoinGear] 金币齿轮#%d完成%d圈: +￥%d",
                        gear.id,
                        completedTurns,
                        reward
                    ))
                    RefreshUI()
                    MarkSaveDirty()
                else
                    MarkSaveDirty(CONFIG.IncomeSaveDelay)
                end
            end
        end
    end

    local generator = networkState_.currencyGenerator
    generator.rewardFlash = math.max(
        0,
        (generator.rewardFlash or 0) - timeStep * 2.5
    )
    local generatorRunning = generator.powered == true
        and (generator.rpm or 0) > 0
    if generatorRunning and not generator.animationRunning then
        generator.animationTime = 0
        generator.animationRunning = true
        print(string.format(
            "[CurrencyGenerator] 动画启动: rpm=%.2f, fps=8",
            generator.rpm or 0
        ))
    elseif not generatorRunning and generator.animationRunning then
        generator.animationRunning = false
        generator.animationTime = 0
        print("[CurrencyGenerator] 动画停止")
    end
    if generatorRunning then
        local generatorStep = math.min(math.max(timeStep, 0), 0.25)
        generator.animationTime = (generator.animationTime or 0)
            + generatorStep
        if gameData_.currencyGeneratorLastDirection ~= 0
            and gameData_.currencyGeneratorLastDirection
                ~= generator.spinDirection then
            gameData_.currencyGeneratorProgress = 0
        end
        gameData_.currencyGeneratorLastDirection = generator.spinDirection
        local completedBefore = math.floor(gameData_.currencyGeneratorProgress)
        gameData_.currencyGeneratorProgress =
            gameData_.currencyGeneratorProgress
                + generator.rpm * generatorStep / 60
        generator.angle = (generator.angle or 0)
            + generator.rpm
                * generatorStep
                * math.pi
                * 2
                / 60
                * generator.spinDirection
        local completedAfter = math.floor(gameData_.currencyGeneratorProgress)
        local completedTurns = completedAfter - completedBefore
        gameData_.currencyGeneratorProgress =
            gameData_.currencyGeneratorProgress - completedAfter
        if completedTurns > 0 then
            local rewardPerTurn = math.floor(
                math.max(0, totalIncomePerSecond_)
                    * GearDefinitions.CurrencyGenerator.rewardProductionSeconds
            )
            local reward = CreditCoins(rewardPerTurn * completedTurns)
            generator.rewardFlash = 1
            incomeEffects_.SpawnPopup(
                generator.x,
                generator.y,
                generator.radius,
                reward
            )
            print(string.format(
                "[CurrencyGenerator] 完成%d圈，按当前产能%.2f/s奖励￥%d",
                completedTurns,
                totalIncomePerSecond_,
                reward
            ))
            RefreshUI()
            MarkSaveDirty(0)
        else
            MarkSaveDirty(CONFIG.IncomeSaveDelay)
        end
    end

    UpdateMiningMachine(timeStep)

    local idleRequest = responsiveLayout_.idleAdRequest
    if idleRequest.inFlight
        and idleRequest.deadline > 0
        and os.time() >= idleRequest.deadline then
        FinishIdleAdRequest(idleRequest.token, {
            success = false,
            msg = "广告响应超时，请稍后重试",
        })
    end

    if saveDirty_ then
        saveTimer_ = saveTimer_ - timeStep
        if saveTimer_ <= 0 then
            SaveNow("自动保存计时完成")
        end
    end
end

function HandleNanoVGRender()
    if responsiveLayout_.loadingActive then
        return
    end
    local renderWidth = responsiveLayout_.screenLogicalWidth
    local renderHeight = responsiveLayout_.screenLogicalHeight
    nvgBeginFrame(vg_, renderWidth, renderHeight, dpr_)
    if responsiveLayout_.rotatePortrait then
        nvgTranslate(vg_, 0, renderHeight)
        nvgRotate(vg_, -math.pi * 0.5)
    end
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
    local visualAngles = GearRenderer.ResolveVisualAngles(
        gameData_.revenueGears,
        connections_,
        mainGearX_,
        mainGearY_,
        mainGearAngle_,
        networkState_.externalNodes
    )
    networkState_.clockDisplay.gearAngle =
        networkState_.clockDisplay.running == true
            and (
                visualAngles[GearDefinitions.ClockInterface.id]
                    or networkState_.clockInterface.angle
                    or 0
            )
        or (networkState_.clockInterface.angle or 0)
    local currentTorque = networkState_.sourceTorque or GetMainTorque()
    local clockLocked = gameData_.lifetimeCoinsEarned
            < GearDefinitions.ClockInterface.requiredLifetimeCoins
        or currentTorque < GearDefinitions.ClockInterface.requiredTorque
    GearRenderer.DrawClockAnimation(
        vg_,
        networkState_.clockDisplay,
        clockLocked
    )
    local clockHelpX, clockHelpY, clockHelpRadius =
        GearRenderer.GetClockHelpCircle(networkState_.clockDisplay)
    GearRenderer.DrawMachineHelpIcon(
        vg_,
        clockHelpX,
        clockHelpY,
        clockHelpRadius
    )
    GearRenderer.DrawPowerCable(
        vg_,
        networkState_.powerGeneratorDisplay,
        networkState_.miningMachine,
        networkState_.powerGeneratorInterface.generating == true,
        warningPhase_
    )
    local currencyGeneratorLocked = currentTorque
        < GearDefinitions.CurrencyGenerator.requiredTorque
    local miningMachineLocked = gameData_.lifetimeCoinsEarned
            < GearDefinitions.MiningMachine.requiredLifetimeCoins
        or currentTorque < GearDefinitions.MiningMachine.requiredTorque
    GearRenderer.DrawCurrencyGenerator(
        vg_,
        networkState_.currencyGenerator,
        gameData_.currencyGeneratorProgress,
        warningPhase_,
        visualAngles[GearDefinitions.CurrencyGenerator.id],
        currencyGeneratorLocked
    )
    GearRenderer.DrawMiningMachine(
        vg_,
        networkState_.miningMachine,
        gameData_.miningProgress,
        responsiveLayout_.NormalizeMiningInventory(),
        GearDefinitions.MiningMachine.maxOre,
        warningPhase_,
        miningMachineLocked
    )
    GearRenderer.DrawPowerGeneratorAnimation(
        vg_,
        networkState_.powerGeneratorDisplay,
        miningMachineLocked
    )
    local currencyHelpX, currencyHelpY, currencyHelpRadius =
        GearRenderer.GetCurrencyGeneratorHelpCircle(
            networkState_.currencyGenerator
        )
    GearRenderer.DrawMachineHelpIcon(
        vg_,
        currencyHelpX,
        currencyHelpY,
        currencyHelpRadius
    )
    local miningHelpX, miningHelpY, miningHelpRadius =
        GearRenderer.GetMiningMachineHelpCircle(
            networkState_.miningMachine
        )
    GearRenderer.DrawMachineHelpIcon(
        vg_,
        miningHelpX,
        miningHelpY,
        miningHelpRadius
    )
    GearRenderer.DrawConnections(
        vg_,
        connections_,
        gameData_.revenueGears,
        mainGearX_,
        mainGearY_,
        networkState_.externalNodes
    )
    local drivetrainRunning = gameData_.autoDriveUnlocked
        and not networkState_.jammed
        and not networkState_.overloaded
    local mainSpeedCapped = drivetrainRunning
        and IsMainSpeedCapped()
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
    if responsiveLayout_.mainOilEffectRemaining > 0 then
        GearRenderer.DrawOilEffect(
            vg_,
            mainGearX_,
            mainGearY_,
            GearDefinitions.GetTipRadius(
                mainGearRadius_,
                GearDefinitions.Main.rings.outer.teeth
            ),
            warningPhase_,
            math.min(
                1,
                responsiveLayout_.mainOilEffectRemaining
                    / GearDefinitions.Get("lubricant").oilEffectDuration
                    * 2
            )
        )
    end

    for _, index in ipairs(layeredIndices) do
        GearRenderer.DrawRevenueGear(
            vg_,
            GetRevenueGear(index),
            false,
            index == selectedGearIndex_,
            visualAngles[index],
            nil,
            warningPhase_
        )
    end

    if draggedGearIndex_ then
        GearRenderer.DrawRevenueGear(
            vg_,
            GetRevenueGear(draggedGearIndex_),
            true,
            draggedGearIndex_ == selectedGearIndex_,
            visualAngles[draggedGearIndex_],
            dragPlacementValid_,
            warningPhase_
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
                angle = shopDrag_.angle,
                connected = false,
                meshed = false,
                jammed = false,
            },
            true,
            false,
            shopDrag_.angle,
            shopDrag_.placementValid
        )
    end

    nvgRestore(vg_)

    for _, popup in ipairs(incomeEffects_.popups) do
        GearRenderer.DrawIncomePopup(
            vg_,
            popup.x * canvasScale_ + canvasOffsetX_,
            popup.y * canvasScale_ + canvasOffsetY_,
            popup.radius * canvasScale_,
            popup.amountText or FormatNumber(popup.amount),
            popup.age / popup.duration
        )
    end

    GearRenderer.DrawFaultIndicator(
        vg_,
        responsiveLayout_.RefreshFaultIndicator(),
        warningPhase_
    )

    nvgEndFrame(vg_)
end

---@param eventType string
---@param eventData ScreenModeEventData
function HandleScreenMode(eventType, eventData)
    local width = eventData:GetInt("Width")
    local height = eventData:GetInt("Height")
    if width <= 0 or height <= 0 then
        width = graphics:GetWidth()
        height = graphics:GetHeight()
    end
    print(string.format(
        "[Layout] 屏幕尺寸变化，保持内部布局: mode=%s, size=%dx%d",
        responsiveLayout_.mode,
        width,
        height
    ))
    if responsiveLayout_.rebuild then
        responsiveLayout_.rebuild()
    else
        RefreshLayout()
    end
end

---@param eventType string
---@param eventData OrientationChangedEventData
function HandleOrientationChanged(eventType, eventData)
    print(string.format(
        "[Layout] 设备方向事件: orientation=%s, size=%dx%d",
        tostring(eventData:GetVariant("Orientation")),
        graphics:GetWidth(),
        graphics:GetHeight()
    ))
end

function HandleMouseWheel(eventType, eventData)
    if responsiveLayout_.homeVisible then
        return
    end
    if shopDrag_.gearType ~= nil
        or activePointerId_ ~= nil
        or pinchActive_ then
        return
    end
    local wheel = eventData:GetInt("Wheel")
    if wheel == 0 then
        return
    end
    local mouseX, mouseY = PhysicalToLogical(
        input.mousePosition.x,
        input.mousePosition.y
    )
    local anchorWorldX, anchorWorldY = ScreenToWorld(mouseX, mouseY)
    local zoomFactor = wheel > 0 and 1.12 or 1 / 1.12
    canvasScale_ = math.max(
        0.45,
        math.min(2.0, canvasScale_ * zoomFactor)
    )
    canvasOffsetX_ = mouseX - anchorWorldX * canvasScale_
    canvasOffsetY_ = mouseY - anchorWorldY * canvasScale_
end

---@param eventType string
---@param eventData MouseMoveEventData
function HandleMouseMove(eventType, eventData)
    if responsiveLayout_.homeVisible then
        return
    end
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 0.01)
        local screenUIX = eventData:GetInt("X") / uiScale
        local screenUIY = eventData:GetInt("Y") / uiScale
        local uiX, uiY = ScreenUIToLayoutUI(screenUIX, screenUIY)
        MoveShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            uiX,
            uiY,
            IsCanvasAtUIPosition(screenUIX, screenUIY)
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
    if responsiveLayout_.homeVisible then
        return
    end
    if eventData:GetInt("Button") ~= MOUSEB_LEFT then
        return
    end
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 0.01)
        local screenUIX = eventData:GetInt("X") / uiScale
        local screenUIY = eventData:GetInt("Y") / uiScale
        local uiX, uiY = ScreenUIToLayoutUI(screenUIX, screenUIY)
        EndShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            uiX,
            uiY,
            IsCanvasAtUIPosition(screenUIX, screenUIY)
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
    if responsiveLayout_.homeVisible then
        return
    end
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 0.01)
        local screenUIX = eventData:GetInt("X") / uiScale
        local screenUIY = eventData:GetInt("Y") / uiScale
        local uiX, uiY = ScreenUIToLayoutUI(screenUIX, screenUIY)
        MoveShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            uiX,
            uiY,
            IsCanvasAtUIPosition(screenUIX, screenUIY)
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
    if responsiveLayout_.homeVisible then
        return
    end
    if shopDrag_.gearType ~= nil then
        local uiScale = math.max(UI.GetScale(), 0.01)
        local screenUIX = eventData:GetInt("X") / uiScale
        local screenUIY = eventData:GetInt("Y") / uiScale
        local uiX, uiY = ScreenUIToLayoutUI(screenUIX, screenUIY)
        EndShopGearDrag(
            shopDrag_.pointerId,
            shopDrag_.pointerType,
            uiX,
            uiY,
            IsCanvasAtUIPosition(screenUIX, screenUIY)
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
    if shopDrag_.gearType ~= nil then
        CancelShopGearDrag(shopDrag_.pointerId, shopDrag_.pointerType)
    end
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
    RefreshHomeAssetDisplay()
    if responsiveLayout_.homeVisible then
        SyncIncomeLeaderboard(true)
    end
    SaveNow("应用回到前台")
end

function HandleExitRequested()
    MarkSaveDirty(0)
    SaveNow("收到退出请求")
end
