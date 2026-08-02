local GearDefinitions = require("GearDefinitions")

local SaveSystem = {}

local SAVE_VERSION = 8
local SAVE_PATH_A = "gear_workshop_save_a.json"
local SAVE_PATH_B = "gear_workshop_save_b.json"
local MAX_SAVED_GEARS = 100

local currentSequence = 0

local function SanitizeInteger(value, defaultValue, minimum)
    if type(value) ~= "number" or value ~= value then
        return defaultValue
    end

    return math.max(minimum, math.floor(value))
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

    local data = {
        version = SAVE_VERSION,
        sequence = SanitizeInteger(decoded.sequence, 0, 0),
        coins = SanitizeInteger(decoded.coins, 0, 0),
        clickLevel = SanitizeInteger(decoded.clickLevel, 1, 1),
        nextGearId = math.max(
            SanitizeInteger(decoded.nextGearId, highestGearId + 1, 1),
            highestGearId + 1
        ),
        revenueGears = gears,
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
        autoDriveLevel = SanitizeInteger(decoded.autoDriveLevel, 0, 0),
        globalIncomeLevel = SanitizeInteger(decoded.globalIncomeLevel, 0, 0),
        decayReductionLevel = SanitizeInteger(decoded.decayReductionLevel, 0, 0),
        offlineIncomeLevel = SanitizeInteger(decoded.offlineIncomeLevel, 0, 0),
        lastActiveTimestamp = SanitizeInteger(decoded.lastActiveTimestamp, 0, 0),
        savedIncomePerSecond = SanitizeNumber(decoded.savedIncomePerSecond, 0, 0),
        pendingOfflineCoins = SanitizeInteger(decoded.pendingOfflineCoins, 0, 0),
        pendingOfflineSeconds = SanitizeInteger(decoded.pendingOfflineSeconds, 0, 0),
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
        return {
            coins = 0,
            clickLevel = 1,
            nextGearId = 1,
            revenueGears = {},
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
            mainTorqueLevel = 0,
            mainCircleIncomeLevel = 0,
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
    end

    currentSequence = selected.sequence
    return {
        coins = selected.coins,
        clickLevel = selected.clickLevel,
        nextGearId = selected.nextGearId,
        revenueGears = selected.revenueGears,
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
        autoDriveLevel = selected.autoDriveLevel,
        globalIncomeLevel = selected.globalIncomeLevel,
        decayReductionLevel = selected.decayReductionLevel,
        offlineIncomeLevel = selected.offlineIncomeLevel,
        lastActiveTimestamp = selected.lastActiveTimestamp,
        savedIncomePerSecond = selected.savedIncomePerSecond,
        pendingOfflineCoins = selected.pendingOfflineCoins,
        pendingOfflineSeconds = selected.pendingOfflineSeconds,
    }
end

function SaveSystem.Save(gameData)
    currentSequence = currentSequence + 1

    local saveData = {
        version = SAVE_VERSION,
        sequence = currentSequence,
        coins = SanitizeInteger(gameData.coins, 0, 0),
        clickLevel = SanitizeInteger(gameData.clickLevel, 1, 1),
        nextGearId = SanitizeInteger(gameData.nextGearId, 1, 1),
        revenueGears = SanitizeGears(gameData.revenueGears),
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
        autoDriveLevel = SanitizeInteger(gameData.autoDriveLevel, 0, 0),
        globalIncomeLevel = SanitizeInteger(gameData.globalIncomeLevel, 0, 0),
        decayReductionLevel = SanitizeInteger(gameData.decayReductionLevel, 0, 0),
        offlineIncomeLevel = SanitizeInteger(gameData.offlineIncomeLevel, 0, 0),
        lastActiveTimestamp = SanitizeInteger(gameData.lastActiveTimestamp, 0, 0),
        savedIncomePerSecond = SanitizeNumber(gameData.savedIncomePerSecond, 0, 0),
        pendingOfflineCoins = SanitizeInteger(gameData.pendingOfflineCoins, 0, 0),
        pendingOfflineSeconds = SanitizeInteger(gameData.pendingOfflineSeconds, 0, 0),
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
