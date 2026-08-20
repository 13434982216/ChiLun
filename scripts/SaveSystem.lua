local GearDefinitions = require("GearDefinitions")

local SaveSystem = {}

local SAVE_VERSION = 25
local MONEY_RESET_VERSION = 20
local SAVE_PATH_A = "gear_workshop_reset_v5_save_a.json"
local SAVE_PATH_B = "gear_workshop_reset_v5_save_b.json"
local MAX_SAVED_GEARS = 100

local currentSequence = 0

local function SanitizeInteger(value, defaultValue, minimum)
    if type(value) ~= "number" or value ~= value then
        return defaultValue
    end

    return math.max(minimum or -math.huge, math.floor(value))
end

local function SanitizeCoordinate(value, defaultValue)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        return defaultValue
    end

    return math.max(-100, math.min(100, value))
end

local function SanitizeNumber(value, defaultValue, minimum)
    if type(value) ~= "number" or value ~= value then
        return defaultValue
    end

    return math.max(minimum, value)
end

local function SanitizeBoolean(value, defaultValue)
    if type(value) == "boolean" then
        return value
    end
    return defaultValue
end

local function SanitizeGearType(value)
    if type(value) == "string" and GearDefinitions.Revenue[value] then
        return value
    end
    return "small"
end

local function SanitizeUnlocks(value, includeWorkshop)
    local result = {}
    if includeWorkshop then
        result.workshop = true
    end
    if type(value) == "table" then
        for key, unlocked in pairs(value) do
            if type(key) == "string" and unlocked == true then
                result[key] = true
            end
        end
    end
    return result
end

local SanitizeGearPurchaseCounts

local function CreatePermanentContentUnlocks(decoded, gears)
    local result = SanitizeUnlocks(
        decoded.permanentContentUnlocks,
        false
    )
    local lifetimeCoins = SanitizeInteger(
        decoded.lifetimeCoinsEarned,
        0,
        0
    )
    local purchaseCounts = SanitizeGearPurchaseCounts(
        decoded.gearPurchaseCounts
    )

    for gearType, definition in pairs(GearDefinitions.Revenue) do
        if definition.purchaseCost > 0
            and (
                lifetimeCoins >= definition.purchaseCost
                or (purchaseCounts[gearType] or 0) > 0
            ) then
            result["gear:" .. gearType] = true
        end
    end
    for _, gear in ipairs(gears) do
        result["gear:" .. gear.gearType] = true
    end
    if decoded.unlockedBuildings
        and decoded.unlockedBuildings.precisionFoundry == true then
        result["gear:momma"] = true
    end
    if SanitizeInteger(decoded.mommaFactoryStock, 0, 0) > 0 then
        result["gear:momma"] = true
    end

    local revealCoins = GearDefinitions.UpgradeRevealCoins
    local upgradeLevels = {
        torque = SanitizeInteger(decoded.mainTorqueLevel, 0, 0),
        circleIncome = SanitizeInteger(
            decoded.mainCircleIncomeLevel,
            0,
            0
        ),
        manualClick = math.max(
            0,
            SanitizeInteger(decoded.clickLevel, 1, 1) - 1
        ),
        permanent = math.max(
            SanitizeInteger(decoded.globalIncomeLevel, 0, 0),
            SanitizeInteger(decoded.decayReductionLevel, 0, 0),
            SanitizeInteger(decoded.offlineIncomeLevel, 0, 0)
        ),
    }
    for upgradeType, unlockCoins in pairs(revealCoins) do
        if lifetimeCoins >= unlockCoins
            or (upgradeLevels[upgradeType] or 0) > 0 then
            result["upgrade:" .. upgradeType] = true
        end
    end
    if SanitizeInteger(decoded.gearEssence, 0, 0) > 0 then
        result["upgrade:permanent"] = true
    end

    return result
end

SanitizeGearPurchaseCounts = function(value)
    local result = {}
    local purchasableTypes = {
        "small",
        "medium",
        "large",
        "compound",
        "lubricant",
        "coin",
        "momma",
    }
    for _, gearType in ipairs(purchasableTypes) do
        result[gearType] = SanitizeInteger(
            type(value) == "table" and value[gearType] or nil,
            0,
            0
        )
    end
    return result
end

local function SanitizeMiningOreInventory(value, legacyOre)
    local definition = GearDefinitions.MiningMachine
    local result = {}
    local remainingCapacity = definition.maxOre
    local source = type(value) == "table" and value or nil
    for _, oreId in ipairs(definition.oreTypeOrder) do
        local fallback = source == nil and oreId == "iron"
                and legacyOre
            or 0
        local amount = SanitizeInteger(
            source and source[oreId] or nil,
            fallback,
            0
        )
        amount = math.min(remainingCapacity, amount)
        result[oreId] = amount
        remainingCapacity = remainingCapacity - amount
    end
    return result, definition.maxOre - remainingCapacity
end

local function SanitizeGears(rawGears)
    local gears = {}
    if type(rawGears) ~= "table" then
        return gears
    end

    for index, rawGear in ipairs(rawGears) do
        if index > MAX_SAVED_GEARS then
            break
        end

        if type(rawGear) == "table" then
            gears[#gears + 1] = {
                id = SanitizeInteger(rawGear.id, index, 1),
                gearType = SanitizeGearType(rawGear.gearType),
                level = SanitizeInteger(rawGear.level, 1, 1),
                xNorm = SanitizeCoordinate(rawGear.xNorm, 0.5),
                yNorm = SanitizeCoordinate(rawGear.yNorm, 0.7),
                anchorX = type(rawGear.anchorX) == "number"
                        and SanitizeCoordinate(rawGear.anchorX, 0)
                    or nil,
                anchorY = type(rawGear.anchorY) == "number"
                        and SanitizeCoordinate(rawGear.anchorY, 0)
                    or nil,
                lubricationRemaining = SanitizeNumber(
                    rawGear.lubricationRemaining,
                    GearDefinitions.Get(rawGear.gearType).lubricationDuration
                        or GearDefinitions.DefaultLubricationDuration,
                    0
                ),
                purchaseCostPaid = type(rawGear.purchaseCostPaid) == "number"
                        and SanitizeInteger(rawGear.purchaseCostPaid, 0, 0)
                    or nil,
                turnProgress = math.min(
                    0.999999,
                    SanitizeNumber(rawGear.turnProgress, 0, 0)
                ),
            }
        end
    end

    return gears
end

local function ReadSlot(path)
    if not fileSystem:FileExists(path) then
        print("[SaveSystem] 存档槽不存在: " .. path)
        return nil
    end

    local file = File(path, FILE_READ)
    if not file:IsOpen() then
        print("[SaveSystem] 无法打开存档槽: " .. path)
        file:Dispose()
        return nil
    end

    local raw = file:ReadString()
    file:Dispose()

    local ok, decoded = pcall(cjson.decode, raw)
    if not ok or type(decoded) ~= "table" then
        print("[SaveSystem] 存档解析失败: " .. path)
        return nil
    end

    local version = SanitizeInteger(decoded.version, 1, 1)
    if version > SAVE_VERSION then
        print("[SaveSystem] 存档版本过新，当前客户端无法读取: " .. path)
        return nil
    end

    local gears = version >= 2 and SanitizeGears(decoded.revenueGears) or {}
    local highestGearId = 0
    for _, gear in ipairs(gears) do
        highestGearId = math.max(highestGearId, gear.id)
    end

    local sanitizedMiningInventory, sanitizedMiningTotal =
        SanitizeMiningOreInventory(
            decoded.miningOreInventory,
            math.min(
                GearDefinitions.MiningMachine.maxOre,
                SanitizeInteger(decoded.miningOre, 0, 0)
            )
        )

    local hasLegacyProgress = version < 25
        and (
            SanitizeInteger(decoded.lifetimeCoinsEarned, 0, 0) > 0
            or SanitizeInteger(decoded.coins, 0, 0) > 0
            or #gears > 0
            or SanitizeInteger(decoded.clickLevel, 1, 1) > 1
            or SanitizeInteger(decoded.mainTorqueLevel, 0, 0) > 0
            or SanitizeInteger(decoded.mainCircleIncomeLevel, 0, 0) > 0
            or SanitizeInteger(decoded.ascensionCount, 0, 0) > 0
            or SanitizeInteger(decoded.gearEssence, 0, 0) > 0
        )

    local data = {
        version = SAVE_VERSION,
        geometryVersion = SanitizeInteger(
            decoded.geometryVersion,
            1,
            1
        ),
        sequence = SanitizeInteger(decoded.sequence, 0, 0),
        coins = version < MONEY_RESET_VERSION
                and 0
            or SanitizeInteger(decoded.coins, 0, 0),
        clickLevel = SanitizeInteger(decoded.clickLevel, 1, 1),
        nextGearId = math.max(
            SanitizeInteger(decoded.nextGearId, highestGearId + 1, 1),
            highestGearId + 1
        ),
        revenueGears = gears,
        gearPurchaseCounts = SanitizeGearPurchaseCounts(
            decoded.gearPurchaseCounts
        ),
        permanentContentUnlocks = CreatePermanentContentUnlocks(
            decoded,
            gears
        ),
        lubricantCooldownRemaining = SanitizeNumber(
            decoded.lubricantCooldownRemaining,
            0,
            0
        ),
        gearEssence = SanitizeInteger(decoded.gearEssence, 0, 0),
        runCoinsEarned = SanitizeInteger(decoded.runCoinsEarned, 0, 0),
        lifetimeCoinsEarned = SanitizeInteger(
            decoded.lifetimeCoinsEarned,
            0,
            0
        ),
        ascensionCount = SanitizeInteger(decoded.ascensionCount, 0, 0),
        metaRevision = SanitizeInteger(decoded.metaRevision, 0, 0),
        unlockedSubMaps = SanitizeUnlocks(
            decoded.unlockedSubMaps,
            true
        ),
        unlockedBuildings = SanitizeUnlocks(
            decoded.unlockedBuildings,
            false
        ),
        growthWindowStartTimestamp = SanitizeInteger(
            decoded.growthWindowStartTimestamp,
            0,
            0
        ),
        growthWindowElapsedSeconds = SanitizeNumber(
            decoded.growthWindowElapsedSeconds,
            0,
            0
        ),
        growthWindowStartIncome = SanitizeNumber(
            decoded.growthWindowStartIncome,
            0,
            0
        ),
        ascensionRecommendationShown = SanitizeBoolean(
            decoded.ascensionRecommendationShown,
            false
        ),
        mommaFactoryStock = SanitizeInteger(
            decoded.mommaFactoryStock,
            0,
            0
        ),
        mommaFactoryProgressSeconds = SanitizeNumber(
            decoded.mommaFactoryProgressSeconds,
            0,
            0
        ),
        mommaFactoryLastTimestamp = SanitizeInteger(
            decoded.mommaFactoryLastTimestamp,
            0,
            0
        ),
        mainTorqueLevel = SanitizeInteger(
            decoded.mainTorqueLevel,
            0,
            0
        ),
        mainCircleIncomeLevel = SanitizeInteger(
            decoded.mainCircleIncomeLevel,
            0,
            0
        ),
        autoDriveUnlocked = SanitizeBoolean(
            decoded.autoDriveUnlocked,
            false
        ),
        gearWarehousePermanentlyUnlocked = SanitizeBoolean(
            decoded.gearWarehousePermanentlyUnlocked,
            SanitizeInteger(decoded.lifetimeCoinsEarned, 0, 0)
                    >= GearDefinitions.Get("small").purchaseCost
                or #gears > 0
        ),
        upgradeRailPermanentlyUnlocked = SanitizeBoolean(
            decoded.upgradeRailPermanentlyUnlocked,
            SanitizeInteger(decoded.lifetimeCoinsEarned, 0, 0)
                    >= GearDefinitions.UpgradeRailUnlockCoins
                or SanitizeInteger(decoded.mainTorqueLevel, 0, 0) > 0
                or SanitizeInteger(decoded.mainCircleIncomeLevel, 0, 0) > 0
                or SanitizeInteger(decoded.clickLevel, 1, 1) > 1
                or SanitizeInteger(decoded.globalIncomeLevel, 0, 0) > 0
                or SanitizeInteger(decoded.decayReductionLevel, 0, 0) > 0
                or SanitizeInteger(decoded.offlineIncomeLevel, 0, 0) > 0
        ),
        autoDriveLevel = SanitizeInteger(decoded.autoDriveLevel, 0, 0),
        globalIncomeLevel = SanitizeInteger(decoded.globalIncomeLevel, 0, 0),
        decayReductionLevel = SanitizeInteger(decoded.decayReductionLevel, 0, 0),
        offlineIncomeLevel = SanitizeInteger(decoded.offlineIncomeLevel, 0, 0),
        lastActiveTimestamp = SanitizeInteger(decoded.lastActiveTimestamp, 0, 0),
        savedIncomePerSecond = SanitizeNumber(decoded.savedIncomePerSecond, 0, 0),
        pendingOfflineCoins = SanitizeInteger(decoded.pendingOfflineCoins, 0, 0),
        pendingOfflineSeconds = SanitizeInteger(decoded.pendingOfflineSeconds, 0, 0),
        idleAdDayKey = SanitizeInteger(decoded.idleAdDayKey, 0, 0),
        idleAdWatchCount = math.min(
            2,
            SanitizeInteger(decoded.idleAdWatchCount, 0, 0)
        ),
        idleEligibleUntil = SanitizeInteger(
            decoded.idleEligibleUntil,
            0,
            0
        ),
        currencyGeneratorProgress = math.min(
            0.999999,
            SanitizeNumber(decoded.currencyGeneratorProgress, 0, 0)
        ),
        currencyGeneratorLastDirection = math.max(
            -1,
            math.min(
                1,
                SanitizeInteger(
                    decoded.currencyGeneratorLastDirection,
                    0,
                    -1
                )
            )
        ),
        miningProgress = math.min(
            0.999999,
            SanitizeNumber(decoded.miningProgress, 0, 0)
        ),
        miningOre = sanitizedMiningTotal,
        miningOreInventory = sanitizedMiningInventory,
        miningDrillLevel = math.min(
            #GearDefinitions.MiningMachine.drillLevels,
            SanitizeInteger(decoded.miningDrillLevel, 1, 1)
        ),
        mainGearTurnProgress = math.min(
            0.999999,
            SanitizeNumber(decoded.mainGearTurnProgress, 0, 0)
        ),
        manualClickIncomeRemainder = math.min(
            0.999999,
            SanitizeNumber(decoded.manualClickIncomeRemainder, 0, 0)
        ),
        lubricantTutorialCompleted = SanitizeBoolean(
            decoded.lubricantTutorialCompleted,
            false
        ),
        lubricantTutorialStep = type(decoded.lubricantTutorialStep) == "string"
                and decoded.lubricantTutorialStep
            or "lubricant_earn",
        tutorialVersion = SanitizeInteger(
            decoded.tutorialVersion,
            hasLegacyProgress and 1 or 0,
            0
        ),
        tutorialStep = type(decoded.tutorialStep) == "string"
                and decoded.tutorialStep
            or "tap_main",
        tutorialCompleted = hasLegacyProgress
            or SanitizeBoolean(decoded.tutorialCompleted, false),
    }

    print(string.format(
        "[SaveSystem] 读取成功: %s, version=%d->%d, sequence=%d, coins=%d, clickLevel=%d, gears=%d",
        path,
        version,
        SAVE_VERSION,
        data.sequence,
        data.coins,
        data.clickLevel,
        #data.revenueGears
    ))
    return data
end

local function CreateNewGameData()
    return {
        geometryVersion = GearDefinitions.GeometryVersion,
        coins = 0,
        clickLevel = 1,
        nextGearId = 1,
        revenueGears = {},
        gearPurchaseCounts = SanitizeGearPurchaseCounts(nil),
        permanentContentUnlocks = {},
        lubricantCooldownRemaining = 0,
        gearEssence = 0,
        runCoinsEarned = 0,
        lifetimeCoinsEarned = 0,
        ascensionCount = 0,
        metaRevision = 3000000,
        unlockedSubMaps = { workshop = true },
        unlockedBuildings = {},
        growthWindowStartTimestamp = 0,
        growthWindowElapsedSeconds = 0,
        growthWindowStartIncome = 0,
        ascensionRecommendationShown = false,
        mommaFactoryStock = 0,
        mommaFactoryProgressSeconds = 0,
        mommaFactoryLastTimestamp = 0,
        mainTorqueLevel = 0,
        mainCircleIncomeLevel = 0,
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
        miningOreInventory = SanitizeMiningOreInventory(nil, 0),
        miningDrillLevel = 1,
        mainGearTurnProgress = 0,
        manualClickIncomeRemainder = 0,
        lubricantTutorialCompleted = false,
        lubricantTutorialStep = "lubricant_earn",
        tutorialVersion = 0,
        tutorialStep = "tap_main",
        tutorialCompleted = false,
    }
end

function SaveSystem.CreateNewGameData()
    currentSequence = 0
    return CreateNewGameData()
end

function SaveSystem.Load()
    local slotA = ReadSlot(SAVE_PATH_A)
    local slotB = ReadSlot(SAVE_PATH_B)
    local selected = nil

    if slotA and slotB then
        selected = slotA.sequence >= slotB.sequence and slotA or slotB
    else
        selected = slotA or slotB
    end

    if not selected then
        currentSequence = 0
        print("[SaveSystem] 未找到有效存档，使用新游戏数据")
        return CreateNewGameData()
    end

    currentSequence = selected.sequence
    return {
        geometryVersion = selected.geometryVersion,
        coins = selected.coins,
        clickLevel = selected.clickLevel,
        nextGearId = selected.nextGearId,
        revenueGears = selected.revenueGears,
        gearPurchaseCounts = selected.gearPurchaseCounts,
        permanentContentUnlocks = selected.permanentContentUnlocks,
        lubricantCooldownRemaining =
            selected.lubricantCooldownRemaining,
        gearEssence = selected.gearEssence,
        runCoinsEarned = selected.runCoinsEarned,
        lifetimeCoinsEarned = selected.lifetimeCoinsEarned,
        ascensionCount = selected.ascensionCount,
        metaRevision = selected.metaRevision,
        unlockedSubMaps = selected.unlockedSubMaps,
        unlockedBuildings = selected.unlockedBuildings,
        growthWindowStartTimestamp = selected.growthWindowStartTimestamp,
        growthWindowElapsedSeconds = selected.growthWindowElapsedSeconds,
        growthWindowStartIncome = selected.growthWindowStartIncome,
        ascensionRecommendationShown = selected.ascensionRecommendationShown,
        mommaFactoryStock = selected.mommaFactoryStock,
        mommaFactoryProgressSeconds = selected.mommaFactoryProgressSeconds,
        mommaFactoryLastTimestamp = selected.mommaFactoryLastTimestamp,
        mainTorqueLevel = selected.mainTorqueLevel,
        mainCircleIncomeLevel = selected.mainCircleIncomeLevel,
        autoDriveUnlocked = selected.autoDriveUnlocked,
        gearWarehousePermanentlyUnlocked =
            selected.gearWarehousePermanentlyUnlocked,
        upgradeRailPermanentlyUnlocked =
            selected.upgradeRailPermanentlyUnlocked,
        autoDriveLevel = selected.autoDriveLevel,
        globalIncomeLevel = selected.globalIncomeLevel,
        decayReductionLevel = selected.decayReductionLevel,
        offlineIncomeLevel = selected.offlineIncomeLevel,
        lastActiveTimestamp = selected.lastActiveTimestamp,
        savedIncomePerSecond = selected.savedIncomePerSecond,
        pendingOfflineCoins = selected.pendingOfflineCoins,
        pendingOfflineSeconds = selected.pendingOfflineSeconds,
        idleAdDayKey = selected.idleAdDayKey,
        idleAdWatchCount = selected.idleAdWatchCount,
        idleEligibleUntil = selected.idleEligibleUntil,
        currencyGeneratorProgress = selected.currencyGeneratorProgress,
        currencyGeneratorLastDirection =
            selected.currencyGeneratorLastDirection,
        miningProgress = selected.miningProgress,
        miningOre = selected.miningOre,
        miningOreInventory = selected.miningOreInventory,
        miningDrillLevel = selected.miningDrillLevel,
        mainGearTurnProgress = selected.mainGearTurnProgress,
        manualClickIncomeRemainder = selected.manualClickIncomeRemainder,
        lubricantTutorialCompleted = selected.lubricantTutorialCompleted,
        lubricantTutorialStep = selected.lubricantTutorialStep,
        tutorialVersion = selected.tutorialVersion,
        tutorialStep = selected.tutorialStep,
        tutorialCompleted = selected.tutorialCompleted,
    }
end

function SaveSystem.Save(gameData)
    currentSequence = currentSequence + 1

    local sanitizedMiningInventory, sanitizedMiningTotal =
        SanitizeMiningOreInventory(
            gameData.miningOreInventory,
            gameData.miningOre or 0
        )

    local saveData = {
        version = SAVE_VERSION,
        geometryVersion = GearDefinitions.GeometryVersion,
        sequence = currentSequence,
        coins = SanitizeInteger(gameData.coins, 0, 0),
        clickLevel = SanitizeInteger(gameData.clickLevel, 1, 1),
        nextGearId = SanitizeInteger(gameData.nextGearId, 1, 1),
        revenueGears = SanitizeGears(gameData.revenueGears),
        gearPurchaseCounts = SanitizeGearPurchaseCounts(
            gameData.gearPurchaseCounts
        ),
        permanentContentUnlocks = SanitizeUnlocks(
            gameData.permanentContentUnlocks,
            false
        ),
        lubricantCooldownRemaining = SanitizeNumber(
            gameData.lubricantCooldownRemaining,
            0,
            0
        ),
        gearEssence = SanitizeInteger(gameData.gearEssence, 0, 0),
        runCoinsEarned = SanitizeInteger(gameData.runCoinsEarned, 0, 0),
        lifetimeCoinsEarned = SanitizeInteger(
            gameData.lifetimeCoinsEarned,
            0,
            0
        ),
        ascensionCount = SanitizeInteger(gameData.ascensionCount, 0, 0),
        metaRevision = SanitizeInteger(gameData.metaRevision, 0, 0),
        unlockedSubMaps = SanitizeUnlocks(
            gameData.unlockedSubMaps,
            true
        ),
        unlockedBuildings = SanitizeUnlocks(
            gameData.unlockedBuildings,
            false
        ),
        growthWindowStartTimestamp = SanitizeInteger(
            gameData.growthWindowStartTimestamp,
            0,
            0
        ),
        growthWindowElapsedSeconds = SanitizeNumber(
            gameData.growthWindowElapsedSeconds,
            0,
            0
        ),
        growthWindowStartIncome = SanitizeNumber(
            gameData.growthWindowStartIncome,
            0,
            0
        ),
        ascensionRecommendationShown = SanitizeBoolean(
            gameData.ascensionRecommendationShown,
            false
        ),
        mommaFactoryStock = SanitizeInteger(
            gameData.mommaFactoryStock,
            0,
            0
        ),
        mommaFactoryProgressSeconds = SanitizeNumber(
            gameData.mommaFactoryProgressSeconds,
            0,
            0
        ),
        mommaFactoryLastTimestamp = SanitizeInteger(
            gameData.mommaFactoryLastTimestamp,
            0,
            0
        ),
        mainTorqueLevel = SanitizeInteger(
            gameData.mainTorqueLevel,
            0,
            0
        ),
        mainCircleIncomeLevel = SanitizeInteger(
            gameData.mainCircleIncomeLevel,
            0,
            0
        ),
        autoDriveUnlocked = SanitizeBoolean(
            gameData.autoDriveUnlocked,
            false
        ),
        gearWarehousePermanentlyUnlocked = SanitizeBoolean(
            gameData.gearWarehousePermanentlyUnlocked,
            false
        ),
        upgradeRailPermanentlyUnlocked = SanitizeBoolean(
            gameData.upgradeRailPermanentlyUnlocked,
            false
        ),
        autoDriveLevel = SanitizeInteger(gameData.autoDriveLevel, 0, 0),
        globalIncomeLevel = SanitizeInteger(gameData.globalIncomeLevel, 0, 0),
        decayReductionLevel = SanitizeInteger(gameData.decayReductionLevel, 0, 0),
        offlineIncomeLevel = SanitizeInteger(gameData.offlineIncomeLevel, 0, 0),
        lastActiveTimestamp = SanitizeInteger(gameData.lastActiveTimestamp, 0, 0),
        savedIncomePerSecond = SanitizeNumber(gameData.savedIncomePerSecond, 0, 0),
        pendingOfflineCoins = SanitizeInteger(gameData.pendingOfflineCoins, 0, 0),
        pendingOfflineSeconds = SanitizeInteger(gameData.pendingOfflineSeconds, 0, 0),
        idleAdDayKey = SanitizeInteger(gameData.idleAdDayKey, 0, 0),
        idleAdWatchCount = math.min(
            2,
            SanitizeInteger(gameData.idleAdWatchCount, 0, 0)
        ),
        idleEligibleUntil = SanitizeInteger(
            gameData.idleEligibleUntil,
            0,
            0
        ),
        currencyGeneratorProgress = math.min(
            0.999999,
            SanitizeNumber(gameData.currencyGeneratorProgress, 0, 0)
        ),
        currencyGeneratorLastDirection = math.max(
            -1,
            math.min(
                1,
                SanitizeInteger(
                    gameData.currencyGeneratorLastDirection,
                    0,
                    -1
                )
            )
        ),
        miningProgress = math.min(
            0.999999,
            SanitizeNumber(gameData.miningProgress, 0, 0)
        ),
        miningOre = sanitizedMiningTotal,
        miningOreInventory = sanitizedMiningInventory,
        miningDrillLevel = math.min(
            #GearDefinitions.MiningMachine.drillLevels,
            SanitizeInteger(gameData.miningDrillLevel, 1, 1)
        ),
        mainGearTurnProgress = math.min(
            0.999999,
            SanitizeNumber(gameData.mainGearTurnProgress, 0, 0)
        ),
        manualClickIncomeRemainder = math.min(
            0.999999,
            SanitizeNumber(gameData.manualClickIncomeRemainder, 0, 0)
        ),
        lubricantTutorialCompleted = SanitizeBoolean(
            gameData.lubricantTutorialCompleted,
            false
        ),
        lubricantTutorialStep = type(gameData.lubricantTutorialStep) == "string"
                and gameData.lubricantTutorialStep
            or "lubricant_earn",
        tutorialVersion = SanitizeInteger(
            gameData.tutorialVersion,
            0,
            0
        ),
        tutorialStep = type(gameData.tutorialStep) == "string"
                and gameData.tutorialStep
            or "tap_main",
        tutorialCompleted = SanitizeBoolean(
            gameData.tutorialCompleted,
            false
        ),
    }

    local ok, encoded = pcall(cjson.encode, saveData)
    if not ok then
        print("[SaveSystem] 存档编码失败: " .. tostring(encoded))
        currentSequence = currentSequence - 1
        return false
    end

    local path = currentSequence % 2 == 1 and SAVE_PATH_A or SAVE_PATH_B
    local file = File(path, FILE_WRITE)
    if not file:IsOpen() then
        print("[SaveSystem] 无法写入存档槽: " .. path)
        file:Dispose()
        currentSequence = currentSequence - 1
        return false
    end

    file:WriteString(encoded)
    file:Flush()
    file:Dispose()

    print(string.format(
        "[SaveSystem] 写入成功: %s, sequence=%d, coins=%d, clickLevel=%d, gears=%d",
        path,
        currentSequence,
        saveData.coins,
        saveData.clickLevel,
        #saveData.revenueGears
    ))
    return true
end

return SaveSystem
