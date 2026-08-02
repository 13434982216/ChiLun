local GearDefinitions = require("GearDefinitions")

local GearSystem = {}

-- 齿圈级啮合区域：
--
--      轴 A                         轴 B
--   (外圈/内圈 rA)  <--- d --->  (外圈/内圈 rB)
--
-- 任意齿圈组合满足 |d - (rA + rB)| <= tolerance 即可建立外啮合边。
-- 每颗复合齿轮只有一个轴节点；边记录参与啮合的齿圈。
-- 动力进入任意齿圈后，整根轴共享 RPM，再从另一齿圈继续输出。

local RING_ORDER = { "outer", "inner" }

local function Distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function GetRingViews(gearType, outerRadius)
    local definitions = GearDefinitions.GetRings(gearType)
    local rings = {}

    for _, ringName in ipairs(RING_ORDER) do
        local ring = definitions[ringName]
        if ring then
            rings[#rings + 1] = {
                name = ringName,
                displayName = ring.name,
                teeth = ring.teeth,
                radius = outerRadius * ring.radiusScale,
            }
        end
    end

    return rings
end

local function FindBestMesh(
    x1,
    y1,
    rings1,
    x2,
    y2,
    rings2,
    tolerance
)
    local distance = Distance(x1, y1, x2, y2)
    ---@type table|nil
    local best = nil

    for _, ringA in ipairs(rings1) do
        for _, ringB in ipairs(rings2) do
            local targetDistance = ringA.radius + ringB.radius
            ---@type number
            local distanceError = math.abs(distance - targetDistance)
            if distanceError <= tolerance
                and (best == nil or distanceError < best.error) then
                best = {
                    error = distanceError,
                    aRing = ringA.name,
                    bRing = ringB.name,
                    aTeeth = ringA.teeth,
                    bTeeth = ringB.teeth,
                    aRadius = ringA.radius,
                    bRadius = ringB.radius,
                }
            end
        end
    end

    return best
end

function GearSystem.IsMeshed(x1, y1, radius1, x2, y2, radius2, tolerance)
    local distance = Distance(x1, y1, x2, y2)
    local targetDistance = radius1 + radius2
    return math.abs(distance - targetDistance) <= tolerance
end

function GearSystem.FindSnapPosition(
    x,
    y,
    radius,
    gears,
    draggedIndex,
    mainX,
    mainY,
    mainRadius,
    snapTolerance,
    draggedGearType
)
    local draggedRings = GetRingViews(draggedGearType or "small", radius)
    ---@type table|nil
    local bestSnap = nil
    ---@type number
    local bestX = x
    ---@type number
    local bestY = y
    local snapped = false
    local snappedRing = nil
    local anchorRing = nil
    ---@type integer|nil
    local snapAnchorIndex = nil

    local function ConsiderAnchor(
        anchorIndex,
        anchorX,
        anchorY,
        anchorType,
        anchorRadius
    )
        local anchorRings = GetRingViews(anchorType, anchorRadius)
        local dx = x - anchorX
        local dy = y - anchorY
        local distance = math.sqrt(dx * dx + dy * dy)
        local dirX = 1.0
        local dirY = 0.0
        if distance > 0.0001 then
            dirX = dx / distance
            dirY = dy / distance
        end

        for _, draggedRing in ipairs(draggedRings) do
            for _, targetRing in ipairs(anchorRings) do
                local targetDistance = draggedRing.radius + targetRing.radius
                local ringSnapTolerance = snapTolerance
                if draggedRing.name == "inner"
                    or targetRing.name == "inner" then
                    ringSnapTolerance = snapTolerance * 1.45
                end
                ---@type number
                local distanceError = math.abs(distance - targetDistance)
                local normalizedError = distanceError / ringSnapTolerance
                local prefersInner = draggedRing.name == "inner"
                    or targetRing.name == "inner"
                if distanceError <= ringSnapTolerance
                    and (bestSnap == nil
                        or normalizedError < bestSnap.score - 0.05
                        or (math.abs(normalizedError - bestSnap.score) <= 0.05
                            and prefersInner
                            and not bestSnap.inner)) then
                    bestSnap = {
                        error = distanceError,
                        score = normalizedError,
                        inner = prefersInner,
                    }
                    bestX = anchorX + dirX * targetDistance
                    bestY = anchorY + dirY * targetDistance
                    snapped = true
                    snappedRing = draggedRing.name
                    anchorRing = targetRing.name
                    snapAnchorIndex = anchorIndex
                end
            end
        end
    end

    ConsiderAnchor(0, mainX, mainY, "main", mainRadius)

    for index, gear in ipairs(gears) do
        if index ~= draggedIndex then
            ConsiderAnchor(index, gear.x, gear.y, gear.gearType, gear.radius)
        end
    end

    return bestX,
        bestY,
        snapped,
        snappedRing,
        anchorRing,
        snapAnchorIndex
end

function GearSystem.FindAxleAssemblyTarget(
    draggedGearType,
    x,
    y,
    gears,
    draggedIndex,
    tolerance
)
    -- 同轴装配捕获区：
    --
    --       小型齿轮中心 ●  →  ( 捕获半径 )  →  大型齿轮轴心 ●
    --
    -- 检测目的：small 的中心进入纯 large 的轴心捕获区后，返回大型齿轮索引；
    -- 这里不建立啮合边，也不允许 large_compound 再次装配。
    -- 边界规则：捕获区外继续走普通齿圈磁吸；拖动目标本身永远跳过。
    if draggedGearType ~= "small" then
        return nil
    end

    local captureDistance = math.max(0, tolerance or 0)
    local captureDistanceSquared = captureDistance * captureDistance
    ---@type integer|nil
    local bestIndex = nil
    ---@type number
    local bestDistanceSquared = captureDistanceSquared + 1

    for index, gear in ipairs(gears) do
        if index ~= draggedIndex and gear.gearType == "large" then
            local distanceSquared =
                (gear.x - x) * (gear.x - x)
                + (gear.y - y) * (gear.y - y)
            if distanceSquared <= captureDistanceSquared
                and distanceSquared < bestDistanceSquared then
                bestIndex = index
                bestDistanceSquared = distanceSquared
            end
        end
    end

    if bestIndex == nil then
        return nil
    end

    local target = gears[bestIndex]
    return bestIndex, target.x, target.y
end

function GearSystem.IsPlacementValid(
    x,
    y,
    radius,
    gearType,
    gears,
    draggedIndex,
    mainX,
    mainY,
    mainRadius,
    tolerance
)
    -- 放置区域示意：
    --   合法啮合：|中心距 - 两个参与齿圈半径之和| <= tolerance
    --   非法穿插：中心距明显小于两颗外圈半径之和，且不匹配任何齿圈组合
    -- 复合齿轮内层接入会在 2D 画面上与外层轮廓重叠；只要内层齿圈
    -- 中心距精确匹配，就视为合法装配，并交由渲染层以前后层级表达。
    local candidateRings = GetRingViews(gearType or "small", radius)

    local function IsValidAgainst(anchorX, anchorY, anchorType, anchorRadius)
        local distance = Distance(x, y, anchorX, anchorY)
        local mesh = FindBestMesh(
            x,
            y,
            candidateRings,
            anchorX,
            anchorY,
            GetRingViews(anchorType, anchorRadius),
            tolerance
        )
        if mesh then
            return true
        end
        return distance >= radius + anchorRadius - tolerance
    end

    if not IsValidAgainst(mainX, mainY, "main", mainRadius) then
        return false
    end

    for index, gear in ipairs(gears) do
        if index ~= draggedIndex
            and not IsValidAgainst(
                gear.x,
                gear.y,
                gear.gearType,
                gear.radius
            ) then
            return false
        end
    end
    return true
end

function GearSystem.Rebuild(
    gears,
    mainX,
    mainY,
    mainRadius,
    tolerance,
    globalIncomeMultiplier,
    transmissionDecay,
    sourcePowered,
    sourceRPM,
    sourceTorque,
    sourceCircleIncome,
    lubricationByLayer,
    fixedLoad
)
    globalIncomeMultiplier = globalIncomeMultiplier or 1
    transmissionDecay = transmissionDecay
        or GearDefinitions.TransmissionDecayPerStage
    sourcePowered = sourcePowered ~= false
    sourceRPM = math.min(
        sourceRPM or GearDefinitions.Main.baseRPM,
        GearDefinitions.Main.maxRPM
    )
    sourceTorque = sourceTorque or GearDefinitions.Main.baseTorque
    sourceCircleIncome = sourceCircleIncome
        or GearDefinitions.Main.baseCircleIncome
    lubricationByLayer = lubricationByLayer or {}
    fixedLoad = math.max(0, fixedLoad or 0)

    local gearCount = #gears
    local adjacency = {}
    local connections = {}

    for index = 0, gearCount do
        adjacency[index] = {}
    end

    local function AddConnection(a, b, mesh)
        local connection = {
            a = a,
            b = b,
            aRing = mesh.aRing,
            bRing = mesh.bRing,
            aTeeth = mesh.aTeeth,
            bTeeth = mesh.bTeeth,
            powered = false,
            meshed = false,
            conflict = false,
        }
        adjacency[a][#adjacency[a] + 1] = connection
        adjacency[b][#adjacency[b] + 1] = connection
        connections[#connections + 1] = connection
    end

    local mainRings = GetRingViews("main", mainRadius)

    for index, gear in ipairs(gears) do
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

        local mesh = FindBestMesh(
            mainX,
            mainY,
            mainRings,
            gear.x,
            gear.y,
            GetRingViews(gear.gearType, gear.radius),
            tolerance
        )
        if mesh then
            AddConnection(0, index, mesh)
        end
    end

    for first = 1, gearCount - 1 do
        local gearA = gears[first]
        for second = first + 1, gearCount do
            local gearB = gears[second]
            local mesh = FindBestMesh(
                gearA.x,
                gearA.y,
                GetRingViews(gearA.gearType, gearA.radius),
                gearB.x,
                gearB.y,
                GetRingViews(gearB.gearType, gearB.radius),
                tolerance
            )
            if mesh then
                AddConnection(first, second, mesh)
            end
        end
    end

    ---@type table<integer, integer|nil>
    local directionByNode = { [0] = 1 }
    ---@type table<integer, number|nil>
    local rpmByNode = { [0] = sourceRPM }
    ---@type table<integer, number|nil>
    local torqueByNode = { [0] = sourceTorque }
    ---@type table<integer, number|nil>
    local depthByNode = { [0] = 0 }
    ---@type integer[]
    local queue = { 0 }
    local queueHead = 1
    local jammed = false
    local conflictPairs = {}

    while queueHead <= #queue do
        local current = queue[queueHead]
        queueHead = queueHead + 1
        local currentDirection = assert(directionByNode[current])
        local currentRPM = assert(rpmByNode[current])
        local currentTorque = assert(torqueByNode[current])
        ---@type integer
        local currentDepth = assert(depthByNode[current])

        for _, connection in ipairs(adjacency[current]) do
            local neighbor = connection.a == current
                and connection.b
                or connection.a
            local driverTeeth = connection.a == current
                and connection.aTeeth
                or connection.bTeeth
            local drivenTeeth = connection.a == current
                and connection.bTeeth
                or connection.aTeeth
            local drivenRing = connection.a == current
                and connection.bRing
                or connection.aRing
            local expectedDirection = math.floor(-currentDirection)

            if directionByNode[neighbor] == nil then
                local gear = gears[neighbor]
                local decayMultiplier = 1 - transmissionDecay
                directionByNode[neighbor] = expectedDirection
                depthByNode[neighbor] = math.floor(currentDepth + 1)
                rpmByNode[neighbor] = currentRPM
                    * driverTeeth
                    / drivenTeeth
                    * decayMultiplier
                    * GearDefinitions.GetSpeedMultiplier(gear.level)

                local transmittedTorque = currentTorque
                    * drivenTeeth
                    / driverTeeth
                    * decayMultiplier
                torqueByNode[neighbor] = math.min(
                    transmittedTorque,
                    GearDefinitions.GetTorqueCapacity(
                        gear.gearType,
                        gear.level
                    )
                )
                gear.parentIndex = current
                gear.inputRing = drivenRing
                queue[#queue + 1] = neighbor
            elseif directionByNode[neighbor] ~= expectedDirection then
                jammed = true
                connection.conflict = true
                conflictPairs[#conflictPairs + 1] = {
                    a = current,
                    b = neighbor,
                }
            end
        end
    end

    local connectedCount = 0
    local meshedCount = 0
    for index, gear in ipairs(gears) do
        if directionByNode[index] ~= nil then
            gear.meshed = true
            meshedCount = meshedCount + 1
        end
    end

    local totalIncomePerSecond = 0.0
    local loadByLayer = {}
    local speedFactorByLayer = {}
    ---@type number
    local totalLoad = fixedLoad
    local speedCapped = sourceRPM >= GearDefinitions.Main.maxRPM

    if not jammed then
        for index, gear in ipairs(gears) do
            if directionByNode[index] ~= nil then
                local depth = math.floor(assert(depthByNode[index]))
                local load = GearDefinitions.GetLoadDemand(
                    gear.gearType,
                    gear.level
                )
                gear.load = load
                gear.transmissionDepth = depth
                loadByLayer[depth] = (loadByLayer[depth] or 0) + load
                totalLoad = totalLoad
                    + load * GearDefinitions.GetLayerLoadWeight(depth)
            end
        end

        local maxDepth = 0
        for depth in pairs(loadByLayer) do
            maxDepth = math.max(maxDepth, depth)
        end
        for depth = 1, maxDepth do
            speedFactorByLayer[depth] =
                GearDefinitions.GetLayerSpeedFactor(
                    loadByLayer[depth] or 0,
                    sourceTorque,
                    lubricationByLayer[depth] or 1
                )
        end

        for index, gear in ipairs(gears) do
            if directionByNode[index] ~= nil then
                local effectiveRPM = assert(rpmByNode[index])
                for layer = 1, gear.transmissionDepth do
                    effectiveRPM = effectiveRPM
                        * (speedFactorByLayer[layer] or 1)
                end
                effectiveRPM = effectiveRPM
                    * GearDefinitions.GetFixedSpeedMultiplier(
                        gear.gearType,
                        gear.transmissionDepth
                    )
                gear.rpmRatio = effectiveRPM
                    / math.max(0.0001, sourceRPM)
            end
        end
    end

    local overloaded = not jammed
        and sourcePowered
        and totalLoad > sourceTorque

    if sourcePowered and not jammed and not overloaded then
        totalIncomePerSecond = sourceCircleIncome
            * globalIncomeMultiplier
            * sourceRPM
            / 60
        for index, gear in ipairs(gears) do
            if directionByNode[index] ~= nil then
                local definition = GearDefinitions.Get(gear.gearType)
                local depth = gear.transmissionDepth
                local rpm = assert(rpmByNode[index])
                for layer = 1, depth do
                    rpm = rpm * (speedFactorByLayer[layer] or 1)
                end
                rpm = rpm * GearDefinitions.GetFixedSpeedMultiplier(
                    gear.gearType,
                    depth
                )
                gear.connected = true
                gear.spinDirection = directionByNode[index]
                gear.rpm = math.min(rpm, GearDefinitions.Main.maxRPM)
                gear.speedCapped = rpm >= GearDefinitions.Main.maxRPM
                speedCapped = speedCapped or gear.speedCapped
                gear.layerSpeedFactor = speedFactorByLayer[depth] or 1
                gear.torque = assert(torqueByNode[index])
                gear.incomePerSecond = definition.baseIncome
                    * GearDefinitions.GetIncomeMultiplier(gear.level)
                    * globalIncomeMultiplier
                    * sourceCircleIncome
                    * gear.rpm
                    / 60
                connectedCount = connectedCount + 1
                totalIncomePerSecond = totalIncomePerSecond
                    + gear.incomePerSecond
            end
        end
    else
        for index, gear in ipairs(gears) do
            if directionByNode[index] ~= nil then
                gear.jammed = jammed
                gear.overloaded = overloaded
                gear.load = GearDefinitions.GetLoadDemand(
                    gear.gearType,
                    gear.level
                )
                gear.transmissionDepth = math.floor(
                    assert(depthByNode[index])
                )
            end
            gear.connected = false
            gear.spinDirection = directionByNode[index] or 0
            gear.rpm = 0
            gear.torque = 0
            gear.incomePerSecond = 0
            gear.layerSpeedFactor = speedFactorByLayer[
                gear.transmissionDepth
            ] or 0
        end
    end

    for _, connection in ipairs(connections) do
        connection.meshed = directionByNode[connection.a] ~= nil
            and directionByNode[connection.b] ~= nil
        connection.powered = sourcePowered
            and not jammed
            and not overloaded
            and connection.meshed
    end

    return connectedCount, connections, {
        jammed = jammed,
        overloaded = overloaded,
        conflictPairs = conflictPairs,
        totalIncomePerSecond = totalIncomePerSecond,
        sourcePowered = sourcePowered,
        sourceRPM = sourcePowered
            and not jammed
            and not overloaded
            and sourceRPM
            or 0,
        sourceTorque = sourceTorque,
        totalLoad = totalLoad,
        fixedLoad = fixedLoad,
        remainingTorque = math.max(0, sourceTorque - totalLoad),
        loadByLayer = loadByLayer,
        speedFactorByLayer = speedFactorByLayer,
        speedCapped = sourcePowered and speedCapped,
        meshedCount = meshedCount,
    }
end

return GearSystem
