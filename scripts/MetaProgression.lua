local MetaProgression = {}

MetaProgression.CloudKey = "gear_workshop_meta_reset_v5"
MetaProgression.LegacyCloudKeys = {
    "gear_workshop_meta_reset_v4",
    "gear_workshop_meta_reset_v3",
    "gear_workshop_meta_reset_v2",
}
MetaProgression.ResetRevision = 3000000
MetaProgression.EssenceCoinRatio = 1000
MetaProgression.RecommendationSeconds = 30 * 60
MetaProgression.RecommendationGrowthRate = 0.05

local function SanitizeInteger(value, defaultValue)
    if type(value) ~= "number" or value ~= value then
        return defaultValue
    end
    return math.max(0, math.floor(value))
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

function MetaProgression.GetAscensionReward(runCoinsEarned)
    return math.floor(
        SanitizeInteger(runCoinsEarned, 0)
            / MetaProgression.EssenceCoinRatio
    )
end

function MetaProgression.GetAscensionProgress(runCoinsEarned)
    local remainder = SanitizeInteger(runCoinsEarned, 0)
        % MetaProgression.EssenceCoinRatio
    return remainder / MetaProgression.EssenceCoinRatio
end

function MetaProgression.CreateCloudSnapshot(gameData)
    return {
        version = 1,
        revision = SanitizeInteger(gameData.metaRevision, 0),
        gearEssence = SanitizeInteger(gameData.gearEssence, 0),
        ascensionCount = SanitizeInteger(gameData.ascensionCount, 0),
        lifetimeCoinsEarned = SanitizeInteger(
            gameData.lifetimeCoinsEarned,
            0
        ),
        globalIncomeLevel = SanitizeInteger(
            gameData.globalIncomeLevel,
            0
        ),
        decayReductionLevel = SanitizeInteger(
            gameData.decayReductionLevel,
            0
        ),
        offlineIncomeLevel = SanitizeInteger(
            gameData.offlineIncomeLevel,
            0
        ),
        tutorialVersion = SanitizeInteger(gameData.tutorialVersion, 0),
        tutorialCompleted = gameData.tutorialCompleted == true,
        unlockedSubMaps = SanitizeUnlocks(
            gameData.unlockedSubMaps,
            true
        ),
        unlockedBuildings = SanitizeUnlocks(
            gameData.unlockedBuildings,
            false
        ),
    }
end

function MetaProgression.CreateResetSnapshot()
    return MetaProgression.CreateCloudSnapshot({
        metaRevision = MetaProgression.ResetRevision,
        gearEssence = 0,
        ascensionCount = 0,
        lifetimeCoinsEarned = 0,
        globalIncomeLevel = 0,
        decayReductionLevel = 0,
        offlineIncomeLevel = 0,
        tutorialVersion = 0,
        tutorialCompleted = false,
        unlockedSubMaps = { workshop = true },
        unlockedBuildings = {},
    })
end

function MetaProgression.NormalizeCloudSnapshot(value)
    if type(value) ~= "table" then
        return nil
    end
    return MetaProgression.CreateCloudSnapshot({
        metaRevision = value.revision,
        gearEssence = value.gearEssence,
        ascensionCount = value.ascensionCount,
        lifetimeCoinsEarned = value.lifetimeCoinsEarned,
        globalIncomeLevel = value.globalIncomeLevel,
        decayReductionLevel = value.decayReductionLevel,
        offlineIncomeLevel = value.offlineIncomeLevel,
        tutorialVersion = value.tutorialVersion,
        tutorialCompleted = value.tutorialCompleted,
        unlockedSubMaps = value.unlockedSubMaps,
        unlockedBuildings = value.unlockedBuildings,
    })
end

function MetaProgression.ApplyCloudSnapshot(gameData, snapshot)
    gameData.metaRevision = snapshot.revision
    gameData.gearEssence = snapshot.gearEssence
    gameData.ascensionCount = snapshot.ascensionCount
    gameData.lifetimeCoinsEarned = snapshot.lifetimeCoinsEarned
    gameData.globalIncomeLevel = snapshot.globalIncomeLevel
    gameData.decayReductionLevel = snapshot.decayReductionLevel
    gameData.offlineIncomeLevel = snapshot.offlineIncomeLevel
    if snapshot.tutorialCompleted == true
        and snapshot.tutorialVersion
            >= SanitizeInteger(gameData.tutorialVersion, 0) then
        gameData.tutorialVersion = snapshot.tutorialVersion
        gameData.tutorialStep = "completed"
        gameData.tutorialCompleted = true
    end
    gameData.unlockedSubMaps = SanitizeUnlocks(
        snapshot.unlockedSubMaps,
        true
    )
    gameData.unlockedBuildings = SanitizeUnlocks(
        snapshot.unlockedBuildings,
        false
    )
end

function MetaProgression.ShouldUseCloud(localData, cloudSnapshot)
    if cloudSnapshot == nil then
        return false
    end
    if cloudSnapshot.tutorialCompleted == true
        and cloudSnapshot.tutorialVersion
            >= SanitizeInteger(localData.tutorialVersion, 0)
        and localData.tutorialCompleted ~= true then
        return true
    end
    return cloudSnapshot.revision
        > SanitizeInteger(localData.metaRevision, 0)
end

return MetaProgression
