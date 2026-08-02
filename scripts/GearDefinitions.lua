local GearDefinitions = {}

GearDefinitions.Main = {
    type = "main",
    name = "金色双层驱动齿轮",
    baseRPM = 1.8,
    maxRPM = 60 * 60,
    baseTorque = 24,
    torquePerLevel = 8,
    autoUnlockTorqueLevel = 3,
    baseCircleIncome = 1,
    circleIncomePerLevel = 1,
    manualClickMax = 39,
    rings = {
        outer = {
            name = "外层大齿圈",
            teeth = 32,
            radiusScale = 1.0,
        },
        inner = {
            name = "内层小齿圈",
            teeth = 12,
            radiusScale = 0.375,
        },
    },
}

GearDefinitions.Revenue = {
    small = {
        type = "small",
        name = "小型收益齿轮",
        teeth = 16,
        radiusScale = 0.5,
        baseTorque = 48,
        baseLoad = 4,
        baseIncome = 1,
        purchaseCost = 15,
        upgradeBaseCost = 20,
    },
    medium = {
        type = "medium",
        name = "中型收益齿轮",
        teeth = 32,
        radiusScale = 1.0,
        baseTorque = 64,
        baseLoad = 7,
        baseIncome = 3,
        purchaseCost = 45,
        upgradeBaseCost = 55,
    },
    large = {
        type = "large",
        name = "大型收益齿轮",
        teeth = 48,
        radiusScale = 1.5,
        baseTorque = 96,
        baseLoad = 11,
        baseIncome = 6,
        purchaseCost = 100,
        upgradeBaseCost = 120,
    },
    large_compound = {
        type = "large_compound",
        name = "大型同轴复合齿轮",
        teeth = 48,
        radiusScale = 1.5,
        baseTorque = 132,
        baseLoad = 14,
        baseIncome = 8,
        purchaseCost = 0,
        upgradeBaseCost = 180,
        fixedSpeedMultiplier = 4.5,
        rings = {
            outer = {
                name = "大型外层齿圈",
                teeth = 48,
                radiusScale = 1.0,
            },
            inner = {
                name = "同轴小齿圈",
                teeth = 16,
                radiusScale = 1 / 3,
            },
        },
    },
    compound = {
        type = "compound",
        name = "双层变速齿轮",
        teeth = 32,
        radiusScale = 1.0,
        baseTorque = 72,
        baseLoad = 9,
        baseIncome = 5,
        purchaseCost = 160,
        upgradeBaseCost = 180,
        rings = {
            outer = {
                name = "外层大齿圈",
                teeth = 32,
                radiusScale = 1.0,
            },
            inner = {
                name = "内层小齿圈",
                teeth = 12,
                radiusScale = 0.375,
            },
        },
    },
    momma = {
        type = "momma",
        name = "母齿轮 Momma Gear",
        teeth = 48,
        radiusScale = 1.5,
        baseTorque = 240,
        baseLoad = 1.5,
        baseIncome = 24,
        purchaseCost = 2500,
        upgradeBaseCost = 3000,
        fixedSpeedMultiplier = 11.25,
        rings = {
            outer = {
                name = "母式外层齿圈",
                teeth = 48,
                radiusScale = 1.0,
            },
            inner = {
                name = "母式内层齿圈",
                teeth = 16,
                radiusScale = 1 / 3,
            },
        },
    },
}

GearDefinitions.TransmissionDecayPerStage = 0.04
GearDefinitions.SpeedUpgradePerLevel = 0.08
GearDefinitions.TorqueUpgradePerLevel = 0.12
GearDefinitions.IncomeUpgradePerLevel = 0.20
GearDefinitions.UpgradeCostGrowth = 1.75

GearDefinitions.GlobalUpgrades = {
    income = {
        name = "全收益倍率",
        baseCost = 180,
        costGrowth = 2.0,
        bonusPerLevel = 0.25,
    },
    decay = {
        name = "传动损耗降低",
        baseCost = 240,
        costGrowth = 2.15,
        reductionPerLevel = 0.005,
        minimumDecay = 0.01,
    },
    offline = {
        name = "离线收益倍率",
        baseCost = 150,
        costGrowth = 1.9,
        baseMultiplier = 0.5,
        bonusPerLevel = 0.25,
    },
}

GearDefinitions.MaxOfflineSeconds = 8 * 60 * 60
GearDefinitions.TorqueUpgradeUnlockCoins = 25
GearDefinitions.LoadPerLevel = 0.06
GearDefinitions.RemoteBranchLoadFactor = 0.22
GearDefinitions.MinimumLayerSpeedFactor = 0.12
GearDefinitions.Ascension = {
    essenceCoinRatio = 1000,
    recommendationSeconds = 30 * 60,
    recommendationGrowthRate = 0.05,
}
GearDefinitions.EssenceUpgrades = {
    income = {
        name = "永恒增产",
        baseCost = 1,
        costGrowth = 1.8,
    },
    decay = {
        name = "永恒润滑",
        baseCost = 2,
        costGrowth = 2.0,
    },
    offline = {
        name = "时流储能",
        baseCost = 1,
        costGrowth = 1.8,
    },
}
GearDefinitions.MetaUnlocks = {
    subMaps = {
        scrapyard = {
            name = "废铜矿区",
            cost = 5,
        },
    },
    buildings = {
        precisionFoundry = {
            name = "巨型齿轮工厂",
            cost = 8,
        },
    },
}
GearDefinitions.FixedSpeedMultipliers = {
    giant = 4.5,
    middle = 6.75,
    remote = 9.0,
    mother = 11.25,
}
GearDefinitions.MommaFactory = {
    buildingId = "precisionFoundry",
    baseProductionSeconds = 15 * 60,
    ascensionSpeedBonusPerCount = 0.03,
    maxAscensionSpeedBonus = 0.45,
    maxStock = 4,
    fixedLoad = 18,
}

GearDefinitions.MainUpgrades = {
    torque = { baseCost = 25, costGrowth = 1.7 },
    circleIncome = { baseCost = 40, costGrowth = 1.85 },
    manualClick = { baseCost = 10, costGrowth = 1.55 },
}

function GearDefinitions.GetMainTorque(level)
    return GearDefinitions.Main.baseTorque
        + level * GearDefinitions.Main.torquePerLevel
end

function GearDefinitions.GetMainCircleIncome(level)
    return GearDefinitions.Main.baseCircleIncome
        + level * GearDefinitions.Main.circleIncomePerLevel
end

function GearDefinitions.GetMainClickIncome(level)
    return math.min(
        GearDefinitions.Main.manualClickMax,
        1 + level
    )
end

function GearDefinitions.GetMainUpgradeCost(upgradeType, level)
    local definition = GearDefinitions.MainUpgrades[upgradeType]
    return math.floor(definition.baseCost * definition.costGrowth ^ level)
end

function GearDefinitions.CanUnlockAutoDrive(torqueLevel)
    return torqueLevel >= GearDefinitions.Main.autoUnlockTorqueLevel
end

function GearDefinitions.GetLoadDemand(gearType, level)
    local definition = GearDefinitions.Get(gearType)
    return definition.baseLoad
        * (1 + (level - 1) * GearDefinitions.LoadPerLevel)
end

function GearDefinitions.GetLayerLoadWeight(depth)
    return GearDefinitions.RemoteBranchLoadFactor ^ math.max(0, depth - 1)
end

function GearDefinitions.GetLayerSpeedFactor(layerLoad, sourceTorque, lubricationMultiplier)
    if layerLoad <= 0 then
        return 1
    end

    local lubricatedLoad = layerLoad * (lubricationMultiplier or 1)
    return math.max(
        GearDefinitions.MinimumLayerSpeedFactor,
        1 / (1 + lubricatedLoad / math.max(1, sourceTorque))
    )
end

function GearDefinitions.GetFixedSpeedMultiplier(gearType, depth)
    local definition = GearDefinitions.Get(gearType)
    if definition.fixedSpeedMultiplier then
        return definition.fixedSpeedMultiplier
    elseif gearType == "compound" then
        return GearDefinitions.FixedSpeedMultipliers.mother
    elseif gearType == "large" then
        return GearDefinitions.FixedSpeedMultipliers.giant
    elseif depth >= 3 then
        return GearDefinitions.FixedSpeedMultipliers.remote
    elseif depth == 2 then
        return GearDefinitions.FixedSpeedMultipliers.middle
    end
    return 1
end

function GearDefinitions.GetMommaFactoryProductionSeconds(ascensionCount)
    local factory = GearDefinitions.MommaFactory
    local speedBonus = math.min(
        factory.maxAscensionSpeedBonus,
        math.max(0, ascensionCount) * factory.ascensionSpeedBonusPerCount
    )
    return factory.baseProductionSeconds * (1 - speedBonus)
end

function GearDefinitions.Get(gearType)
    return GearDefinitions.Revenue[gearType] or GearDefinitions.Revenue.small
end

function GearDefinitions.GetRings(gearType)
    if gearType == "main" then
        return GearDefinitions.Main.rings
    end

    local definition = GearDefinitions.Get(gearType)
    if definition.rings then
        return definition.rings
    end

    return {
        outer = {
            name = "单层齿圈",
            teeth = definition.teeth,
            radiusScale = 1.0,
        },
    }
end

function GearDefinitions.IsCompound(gearType)
    return gearType == "main"
        or GearDefinitions.Get(gearType).rings ~= nil
end

function GearDefinitions.GetUpgradeCost(gearType, level)
    local definition = GearDefinitions.Get(gearType)
    return math.floor(definition.upgradeBaseCost * GearDefinitions.UpgradeCostGrowth ^ (level - 1))
end

function GearDefinitions.GetSpeedMultiplier(level)
    return 1 + (level - 1) * GearDefinitions.SpeedUpgradePerLevel
end

function GearDefinitions.GetTorqueCapacity(gearType, level)
    local definition = GearDefinitions.Get(gearType)
    return definition.baseTorque * (1 + (level - 1) * GearDefinitions.TorqueUpgradePerLevel)
end

function GearDefinitions.GetIncomeMultiplier(level)
    return 1 + (level - 1) * GearDefinitions.IncomeUpgradePerLevel
end

function GearDefinitions.GetGlobalUpgradeCost(upgradeType, level)
    local definition = GearDefinitions.EssenceUpgrades[upgradeType]
    return math.max(
        1,
        math.floor(definition.baseCost * definition.costGrowth ^ level)
    )
end

function GearDefinitions.GetAscensionReward(runCoinsEarned)
    return math.floor(
        math.max(0, runCoinsEarned)
            / GearDefinitions.Ascension.essenceCoinRatio
    )
end

function GearDefinitions.GetMetaUnlock(category, unlockId)
    local definitions = GearDefinitions.MetaUnlocks[category]
    return definitions and definitions[unlockId] or nil
end

function GearDefinitions.GetGlobalIncomeMultiplier(level)
    return 1 + level * GearDefinitions.GlobalUpgrades.income.bonusPerLevel
end

function GearDefinitions.GetTransmissionDecay(level)
    local definition = GearDefinitions.GlobalUpgrades.decay
    return math.max(
        definition.minimumDecay,
        GearDefinitions.TransmissionDecayPerStage
            - level * definition.reductionPerLevel
    )
end

function GearDefinitions.GetOfflineMultiplier(level)
    local definition = GearDefinitions.GlobalUpgrades.offline
    return definition.baseMultiplier + level * definition.bonusPerLevel
end

function GearDefinitions.CalculateOfflineReward(
    savedIncomePerSecond,
    elapsedSeconds,
    offlineLevel
)
    local effectiveSeconds = math.floor(math.min(
        math.max(0, elapsedSeconds),
        GearDefinitions.MaxOfflineSeconds
    ))
    local reward = math.floor(
        math.max(0, savedIncomePerSecond)
            * effectiveSeconds
            * GearDefinitions.GetOfflineMultiplier(offlineLevel)
    )
    return reward, effectiveSeconds
end

return GearDefinitions
