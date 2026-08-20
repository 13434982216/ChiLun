local GearDefinitions = {}

GearDefinitions.GeometryVersion = 4
GearDefinitions.TeethPerMainRadius = 16
GearDefinitions.GearProfile = {
    addendum = 1.0,
    dedendum = 1.25,
    tipHalfWidth = 0.16,
    pitchHalfWidth = 0.25,
    rootHalfWidth = 0.38,
}

function GearDefinitions.GetToothModule(pitchRadius, teeth)
    return pitchRadius * 2 / math.max(1, teeth)
end

function GearDefinitions.GetTipRadius(pitchRadius, teeth)
    return pitchRadius
        + GearDefinitions.GetToothModule(pitchRadius, teeth)
            * GearDefinitions.GearProfile.addendum
end

function GearDefinitions.GetRootRadius(pitchRadius, teeth)
    return math.max(
        0,
        pitchRadius
            - GearDefinitions.GetToothModule(pitchRadius, teeth)
                * GearDefinitions.GearProfile.dedendum
    )
end

GearDefinitions.Main = {
    type = "main",
    name = "金色双层驱动齿轮",
    baseRPM = 1.8,
    maxRPM = 60 * 60,
    baseTorque = 0,
    torquePerLevel = 1.0,
    autoUnlockTorqueLevel = 1,
    baseCircleIncome = 1,
    circleIncomePerLevel = 1,
    baseManualClickIncome = 1.00,
    manualClickGrowth = 1.30,
    manualClickMax = 39,
    rings = {
        outer = {
            name = "外层大齿圈",
            teeth = 16,
            radiusScale = 1.0,
        },
        inner = {
            name = "内层小齿圈",
            teeth = 6,
            radiusScale = 0.375,
        },
    },
}

GearDefinitions.CurrencyGenerator = {
    id = "currencyGenerator",
    name = "货币生成器",
    radiusScale = 1.0,
    requiredTorque = 4.0,
    load = 0.25,
    rewardProductionSeconds = 150,
    xOffsetInMainRadii = 2.0,
    yOffsetInMainRadii = -27.6,
    rings = {
        outer = {
            name = "外露传动齿圈",
            teeth = 16,
            radiusScale = 1.0,
        },
    },
}

GearDefinitions.MiningMachine = {
    id = "miningMachine",
    name = "扭矩矿机",
    radiusScale = 1.0,
    requiredLifetimeCoins = 100000000,
    requiredTorque = 100.0,
    idealTorque = 140.0,
    load = 0.45,
    minRPM = 26.0,
    idealMinRPM = 26.0,
    idealMaxRPM = 40.0,
    maxRPM = 60.0,
    maxOre = 100,
    oreTypeOrder = {
        "iron",
        "copper",
        "silver",
        "gold",
        "crystal",
    },
    oreTypes = {
        iron = {
            id = "iron",
            name = "铁矿石",
            rarity = "常见",
            weight = 55,
            sellCoins = 25,
        },
        copper = {
            id = "copper",
            name = "铜矿石",
            rarity = "常见",
            weight = 25,
            sellCoins = 45,
        },
        silver = {
            id = "silver",
            name = "银矿石",
            rarity = "稀有",
            weight = 12,
            sellCoins = 90,
        },
        gold = {
            id = "gold",
            name = "金矿石",
            rarity = "史诗",
            weight = 6,
            sellCoins = 180,
        },
        crystal = {
            id = "crystal",
            name = "晶核矿",
            rarity = "传说",
            weight = 2,
            sellCoins = 500,
        },
    },
    deliveryOre = 5,
    deliveryCoins = 260,
    xOffsetInMainRadii = 41.0,
    yOffsetInMainRadii = 0.4,
    drillLevels = {
        { cycleSeconds = 90, orePerCycle = 8 },
        { cycleSeconds = 78, orePerCycle = 8, coinCost = 180, oreCost = 12 },
        { cycleSeconds = 66, orePerCycle = 8, coinCost = 550, oreCost = 35 },
        { cycleSeconds = 66, orePerCycle = 10, coinCost = 1400, oreCost = 80 },
    },
    rings = {
        outer = {
            name = "矿机传动齿圈",
            teeth = 16,
            radiusScale = 1.0,
        },
    },
}

GearDefinitions.PowerGeneratorInterface = {
    id = "powerGeneratorInterface",
    name = "发电机专用传动接口",
    radiusScale = 1.0,
    requiredTorque = GearDefinitions.MiningMachine.requiredTorque,
    load = GearDefinitions.MiningMachine.load,
    rings = {
        outer = {
            name = "专用接口齿圈",
            teeth = 16,
            radiusScale = 1.0,
        },
    },
}

GearDefinitions.ClockInterface = {
    id = "clockInterface",
    name = "增益钟表传动接口",
    radiusScale = 1.0,
    requiredLifetimeCoins = 200000000,
    requiredTorque = 50.0,
    load = 0.20,
    directIncomeMultiplier = 1.20,
    rings = {
        outer = {
            name = "钟表黄铜接口齿圈",
            teeth = 16,
            radiusScale = 1.0,
        },
    },
}

GearDefinitions.Revenue = {
    small = {
        type = "small",
        name = "小型传动齿轮",
        teeth = 16,
        radiusScale = 1.0,
        baseTorque = 48,
        baseLoad = 0.25,
        purchaseCost = 100,
        upgradeBaseCost = 20,
    },
    medium = {
        type = "medium",
        name = "中型传动齿轮",
        teeth = 24,
        radiusScale = 1.5,
        baseTorque = 64,
        baseLoad = 0.5,
        purchaseCost = 250,
        upgradeBaseCost = 55,
    },
    large = {
        type = "large",
        name = "大型传动齿轮",
        teeth = 32,
        radiusScale = 2.0,
        baseTorque = 96,
        baseLoad = 0.75,
        purchaseCost = 500,
        upgradeBaseCost = 120,
        incomeBonusPerLevel = 0.15,
    },
    large_compound = {
        type = "large_compound",
        name = "巨型同轴复合齿轮",
        teeth = 32,
        radiusScale = 2.0,
        baseTorque = 132,
        baseLoad = 1.0,
        purchaseCost = 0,
        upgradeBaseCost = 180,
        fixedSpeedMultiplier = 4.5,
        incomeBonusPerLevel = 0.20,
        rings = {
            outer = {
                name = "大型外层齿圈",
                teeth = 32,
                radiusScale = 1.0,
            },
            inner = {
                name = "同轴小齿圈",
                teeth = 16,
                radiusScale = 0.5,
            },
        },
    },
    compound = {
        type = "compound",
        name = "双层变速齿轮",
        teeth = 24,
        radiusScale = 1.5,
        baseTorque = 72,
        baseLoad = 0.75,
        purchaseCost = 1000,
        upgradeBaseCost = 180,
        rings = {
            outer = {
                name = "外层大齿圈",
                teeth = 24,
                radiusScale = 1.0,
            },
            inner = {
                name = "内层小齿圈",
                teeth = 12,
                radiusScale = 0.5,
            },
        },
    },
    lubricant = {
        type = "lubricant",
        name = "巡游润滑齿轮",
        teeth = 8,
        radiusScale = 0.28,
        baseTorque = 0,
        baseLoad = 0,
        purchaseCost = 750,
        upgradeBaseCost = 100,
        lubricationDuration = 90,
        speedBonusPerLevel = 0.25,
        lifetimeBonusPerLevel = 0.10,
        cooldownSeconds = 20,
        lubricationLoadMultiplier = 0.35,
        patrolSpeedScale = 1.65,
        patrolOrbitSeconds = 1.8,
        autonomousRPM = 48,
        oilEffectDuration = 8,
    },
    coin = {
        type = "coin",
        name = "大型金币齿轮",
        teeth = 32,
        radiusScale = 2.0,
        baseTorque = 84,
        baseLoad = 1.25,
        purchaseCost = 5000,
        upgradeBaseCost = 750,
        baseRewardPerTurn = 10,
    },
    momma = {
        type = "momma",
        name = "母齿轮 Momma Gear",
        teeth = 40,
        radiusScale = 2.5,
        baseTorque = 240,
        baseLoad = 0.25,
        purchaseCost = 2500,
        upgradeBaseCost = 3000,
        fixedSpeedMultiplier = 11.25,
        incomeBonusPerLevel = 0.20,
        rings = {
            outer = {
                name = "母式外层齿圈",
                teeth = 40,
                radiusScale = 1.0,
            },
            inner = {
                name = "母式内层齿圈",
                teeth = 20,
                radiusScale = 0.5,
            },
        },
    },
}

GearDefinitions.TransmissionDecayPerStage = 0.04
GearDefinitions.DefaultLubricationDuration = 60
GearDefinitions.SpeedUpgradePerLevel = 0.08
GearDefinitions.TorqueUpgradePerLevel = 0.12
GearDefinitions.UpgradeCostGrowth = 1.75
GearDefinitions.PurchaseCostGrowth = 1.15

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
GearDefinitions.UpgradeRailUnlockCoins = 25
GearDefinitions.UpgradeRevealCoins = {
    torque = 25,
    circleIncome = 50,
    manualClick = 75,
    permanent = 200,
}
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
    fixedLoad = 0.25,
}

GearDefinitions.MainUpgrades = {
    torque = { baseCost = 25, costGrowth = 1.7 },
    circleIncome = { baseCost = 50, costGrowth = 1.85 },
    manualClick = { baseCost = 75, costGrowth = 1.55 },
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
    local safeLevel = math.max(0, level or 0)
    return math.min(
        GearDefinitions.Main.manualClickMax,
        GearDefinitions.Main.baseManualClickIncome
            * GearDefinitions.Main.manualClickGrowth ^ safeLevel
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
        1 / (
            1
            + lubricatedLoad / math.max(
                GearDefinitions.Main.torquePerLevel,
                sourceTorque
            )
        )
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

function GearDefinitions.GetPurchaseCost(gearType, purchaseCount)
    local definition = GearDefinitions.Get(gearType)
    local safeCount = math.max(0, math.floor(purchaseCount or 0))
    local currentCost = math.max(
        0,
        math.ceil(
            definition.purchaseCost
                * GearDefinitions.PurchaseCostGrowth ^ safeCount
        )
    )
    if definition.purchaseCost > 0 and safeCount > 0 then
        local previousCost = math.ceil(
            definition.purchaseCost
                * GearDefinitions.PurchaseCostGrowth ^ (safeCount - 1)
        )
        return math.max(previousCost + 1, currentCost)
    end
    return currentCost
end

function GearDefinitions.GetRings(gearType)
    if gearType == "main" then
        return GearDefinitions.Main.rings
    elseif gearType == GearDefinitions.CurrencyGenerator.id then
        return GearDefinitions.CurrencyGenerator.rings
    elseif gearType == GearDefinitions.MiningMachine.id then
        return GearDefinitions.MiningMachine.rings
    elseif gearType == GearDefinitions.PowerGeneratorInterface.id then
        return GearDefinitions.PowerGeneratorInterface.rings
    elseif gearType == GearDefinitions.ClockInterface.id then
        return GearDefinitions.ClockInterface.rings
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

function GearDefinitions.GetSpecialIncomeBonus(gearType, level)
    local definition = GearDefinitions.Get(gearType)
    return math.max(0, (level or 1) - 1)
        * (definition.incomeBonusPerLevel or 0)
end

function GearDefinitions.GetLubricantSpeedMultiplier(level)
    local definition = GearDefinitions.Get("lubricant")
    return 1
        + math.max(0, (level or 1) - 1)
            * (definition.speedBonusPerLevel or 0)
end

function GearDefinitions.GetLubricationDuration(level)
    local definition = GearDefinitions.Get("lubricant")
    return definition.lubricationDuration
        * (
            1
            + math.max(0, (level or 1) - 1)
                * (definition.lifetimeBonusPerLevel or 0)
        )
end

function GearDefinitions.GetTorqueCapacity(gearType, level)
    local definition = GearDefinitions.Get(gearType)
    return definition.baseTorque * (1 + (level - 1) * GearDefinitions.TorqueUpgradePerLevel)
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
