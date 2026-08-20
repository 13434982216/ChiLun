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

local function HasCompatiblePitch(ringA, ringB)
    local left = ringA.radius * ringB.teeth
    local right = ringB.radius * ringA.teeth
    local scale = math.max(1, math.abs(left), math.abs(right))
    return math.abs(left - right) <= scale * 0.001
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
            if HasCompatiblePitch(ringA, ringB) then
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
    end

    return best
end

function GearSystem.ComputeDrivenAngle(
    parentAngle,
    contactAngle,
    parentTeeth,
    childTeeth
)
    local safeParentTeeth = math.max(1, parentTeeth)
    local safeChildTeeth = math.max(1, childTeeth)
    local toothRatio = safeParentTeeth / safeChildTeeth
    return (
        (1 + toothRatio) * contactAngle
            + (toothRatio - 1) * math.pi * 0.5
            - math.pi / safeChildTeeth
            - toothRatio * parentAngle
    ) % (math.pi * 2)
end

function GearSystem.GetPeriodicPhaseError(actualAngle, expectedAngle, teeth)
    local period = math.pi * 2 / math.max(1, teeth)
    return math.abs(
        (actualAngle - expectedAngle + period * 0.5) % period
            - period * 0.5
    )
end

function GearSystem.IsMeshed(x1, y1, radius1, x2, y2, radius2, tolerance)
    local distance = Distance(x1, y1, x2, y2)
    local targetDistance = radius1 + radius2
    return math.abs(distance - targetDistance) <= tolerance
end

function GearSystem.GetMeshInfo(
    firstType,
    firstX,
    firstY,
    firstRadius,
    secondType,
    secondX,
    secondY,
    secondRadius,
    tolerance
)
    return FindBestMesh(
        firstX,
        firstY,
        GetRingViews(firstType, firstRadius),
        secondX,
        secondY,
        GetRingViews(secondType, secondRadius),
        tolerance
    )
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
    draggedGearType,
    fixedAnchors
)
    local draggedRings = GetRingViews(draggedGearType or "small", radius)
    if draggedGearType == "lubricant" then
        return x, y, false, nil, nil, nil
    end
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
                if HasCompatiblePitch(draggedRing, targetRing) then
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
    end

    ConsiderAnchor(0, mainX, mainY, "main", mainRadius)

    for index, gear in ipairs(gears) do
        if index ~= draggedIndex and gear.gearType ~= "lubricant" then
            ConsiderAnchor(index, gear.x, gear.y, gear.gearType, gear.radius)
        end
    end

    for _, anchor in ipairs(fixedAnchors or {}) do
        ConsiderAnchor(
            anchor.id,
            anchor.x,
            anchor.y,
            anchor.gearType,
            anchor.radius
        )
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
    --       被拖齿轮中心 ●  →  ( 捕获半径 )  →  异尺寸齿轮轴心 ●
    --
    -- 检测目的：普通 small 与普通 large 中任意一方的中心进入另一方轴心
    -- 捕获区后，返回目标齿轮索引；这里不建立啮合边，也不允许复合齿轮
    -- 再次装配。边界规则：捕获区外继续走普通齿圈磁吸；拖动目标本身
    -- 永远跳过，同尺寸齿轮不能同轴装配。
    if draggedGearType == "lubricant" then
        return nil
    end
    local targetGearType = draggedGearType == "small" and "large"
        or draggedGearType == "large" and "small"
        or nil
    if targetGearType == nil then
        return nil
    end

    local captureDistance = math.max(0, tolerance or 0)
    local captureDistanceSquared = captureDistance * captureDistance
    ---@type integer|nil
    local bestIndex = nil
    ---@type number
    local bestDistanceSquared = captureDistanceSquared + 1

    for index, gear in ipairs(gears) do
        if index ~= draggedIndex and gear.gearType == targetGearType then
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
    tolerance,
    fixedAnchors
)
    -- 放置区域示意：
    --   合法啮合：|中心距 - 两个参与齿圈半径之和| <= tolerance
    --   非法穿插：中心距明显小于两颗外圈半径之和，且不匹配任何齿圈组合
    -- 复合齿轮内层接入会在 2D 画面上与外层轮廓重叠；只要内层齿圈
    -- 中心距精确匹配，就视为合法装配，并交由渲染层以前后层级表达。
    if gearType == "lubricant" then
        return true
    end
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
            and gear.gearType ~= "lubricant"
            and not IsValidAgainst(
                gear.x,
                gear.y,
                gear.gearType,
                gear.radius
            ) then
            return false
        end
    end

    for _, anchor in ipairs(fixedAnchors or {}) do
        if anchor.bodyX and anchor.bodyY
            and anchor.bodyWidth and anchor.bodyHeight then
            local closestX = math.max(
                anchor.bodyX - anchor.bodyWidth * 0.5,
                math.min(x, anchor.bodyX + anchor.bodyWidth * 0.5)
            )
            local closestY = math.max(
                anchor.bodyY - anchor.bodyHeight * 0.5,
                math.min(y, anchor.bodyY + anchor.bodyHeight * 0.5)
            )
            if Distance(x, y, closestX, closestY)
                < radius - tolerance * 0.25 then
                return false
            end
        end
        if not IsValidAgainst(
            anchor.x,
            anchor.y,
            anchor.gearType,
            anchor.radius
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
    lubricationByLayer,
    fixedLoad,
    externalNodes
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
    lubricationByLayer = lubricationByLayer or {}
    fixedLoad = math.max(0, fixedLoad or 0)
    externalNodes = externalNodes or {}

    local gearCount = #gears
    local adjacency = {}
    local connections = {}
    local externalById = {}

    for index = 0, gearCount do
        adjacency[index] = {}
    end
    for _, node in ipairs(externalNodes) do
        externalById[node.id] = node
        adjacency[node.id] = {}
        node.meshed = false
        node.connected = false
        node.powered = false
        node.jammed = false
        node.overloaded = false
        node.rpm = 0
        node.spinDirection = 0
        node.torque = 0
        node.transmissionDepth = 0
        node.parentIndex = nil
        node.inputRing = nil
        node.dynamicLoad = 0
        node.status = "unmeshed"
    end

    local function AddConnection(a, b, mesh)
        local connection = {
            a = a,
            b = b,
            aRing = mesh.aRing,
            bRing = mesh.bRing,
            aTeeth = mesh.aTeeth,
            bTeeth = mesh.bTeeth,
            aRadius = mesh.aRadius,
            bRadius = mesh.bRadius,
            powered = false,
            meshed = false,
            conflict = false,
            phaseConflict = false,
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
        gear.localJammed = false
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
        gear.lubricated = false
        gear.lubricationSource = false
        gear.maintenanceJammed = false
        gear.autonomous = gear.gearType == "lubricant"

        if gear.gearType ~= "lubricant" then
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
    end

    for first = 1, gearCount - 1 do
        local gearA = gears[first]
        if gearA.gearType ~= "lubricant" then
            for second = first + 1, gearCount do
                local gearB = gears[second]
                if gearB.gearType ~= "lubricant" then
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
        end
    end

    for _, node in ipairs(externalNodes) do
        for index, gear in ipairs(gears) do
            if gear.gearType ~= "lubricant" then
                local mesh = FindBestMesh(
                    gear.x,
                    gear.y,
                    GetRingViews(gear.gearType, gear.radius),
                    node.x,
                    node.y,
                    GetRingViews(node.gearType, node.radius),
                    tolerance
                )
                if mesh then
                    AddConnection(index, node.id, mesh)
                    node.meshed = true
                end
            end
        end
    end

    ---@type table<integer|string, integer|nil>
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

        if externalById[current] == nil then
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
                local gear = type(neighbor) == "number"
                    and gears[neighbor]
                    or nil
                local node = externalById[neighbor]
                local decayMultiplier = 1 - transmissionDecay
                directionByNode[neighbor] = expectedDirection
                depthByNode[neighbor] = math.floor(currentDepth + 1)
                rpmByNode[neighbor] = currentRPM
                    * driverTeeth
                    / drivenTeeth
                    * decayMultiplier
                    * (gear
                        and GearDefinitions.GetSpeedMultiplier(gear.level)
                        or 1)

                local transmittedTorque = currentTorque
                    * drivenTeeth
                    / driverTeeth
                    * decayMultiplier
                torqueByNode[neighbor] = gear
                    and math.min(
                        transmittedTorque,
                        GearDefinitions.GetTorqueCapacity(
                            gear.gearType,
                            gear.level
                        )
                    )
                    or transmittedTorque
                if gear then
                    gear.parentIndex = current
                    gear.inputRing = drivenRing
                elseif node then
                    node.parentIndex = current
                    node.inputRing = drivenRing
                end
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
    end

    -- 在齿距周期内验证所有闭环边的相位。BFS 首次访问决定基准相位，
    -- 后续非树边必须给出等价相位，否则齿顶会与齿顶相撞。
    local function GetNodePosition(nodeId)
        if nodeId == 0 then
            return mainX, mainY
        elseif type(nodeId) == "number" then
            local gear = gears[nodeId]
            return gear.x, gear.y
        end
        local node = externalById[nodeId]
        return node.x, node.y
    end

    ---@type table<integer|string, number>
    local phaseByNode = { [0] = 0 }
    ---@type table<integer|string, boolean>
    local phaseVisited = {}
    ---@type (integer|string)[]
    local phaseQueue = { 0 }
    local phaseHead = 1
    while phaseHead <= #phaseQueue do
        local current = phaseQueue[phaseHead]
        phaseHead = phaseHead + 1
        if not phaseVisited[current] then
            phaseVisited[current] = true
            local currentX, currentY = GetNodePosition(current)
            for _, connection in ipairs(adjacency[current]) do
                local neighbor = connection.a == current
                    and connection.b
                    or connection.a
                if directionByNode[neighbor] ~= nil then
                    local neighborX, neighborY = GetNodePosition(neighbor)
                    local driverTeeth = connection.a == current
                        and connection.aTeeth
                        or connection.bTeeth
                    local drivenTeeth = connection.a == current
                        and connection.bTeeth
                        or connection.aTeeth
                    local expectedPhase = GearSystem.ComputeDrivenAngle(
                        phaseByNode[current],
                        math.atan(
                            neighborY - currentY,
                            neighborX - currentX
                        ),
                        driverTeeth,
                        drivenTeeth
                    )
                    if phaseByNode[neighbor] == nil then
                        phaseByNode[neighbor] = expectedPhase
                        phaseQueue[#phaseQueue + 1] = neighbor
                    elseif GearSystem.GetPeriodicPhaseError(
                        phaseByNode[neighbor],
                        expectedPhase,
                        drivenTeeth
                    ) > 0.0001 then
                        if not connection.phaseConflict then
                            connection.phaseConflict = true
                            connection.conflict = true
                            jammed = true
                            conflictPairs[#conflictPairs + 1] = {
                                a = current,
                                b = neighbor,
                                reason = "phase",
                            }
                        end
                    end
                end
            end
        end
    end

    local connectedCount = 0
    local meshedCount = 0
    local transmissionJammed = jammed
    local maintenanceJammed = false
    ---@type integer|nil
    local lubricationSourceGearId = nil
    for index, gear in ipairs(gears) do
        if gear.gearType == "lubricant" then
            gear.meshed = true
            meshedCount = meshedCount + 1
            if (gear.lubricationRemaining or 0) > 0
                and (lubricationSourceGearId == nil
                    or gear.id < lubricationSourceGearId) then
                lubricationSourceGearId = gear.id
            end
        elseif directionByNode[index] ~= nil then
            gear.meshed = true
            meshedCount = meshedCount + 1
        end
    end
    local lubricationAvailable = lubricationSourceGearId ~= nil

    local totalIncomePerSecond = 0.0
    local loadByLayer = {}
    local speedFactorByLayer = {}
    ---@type number
    local totalLoad = fixedLoad
    local speedCapped = sourceRPM >= GearDefinitions.Main.maxRPM

    for _, node in ipairs(externalNodes) do
        if directionByNode[node.id] ~= nil then
            node.connected = true
            node.dynamicLoad = math.max(0, node.load or 0)
            node.transmissionDepth = math.floor(
                assert(depthByNode[node.id])
            )
            node.spinDirection = directionByNode[node.id]
            node.torque = assert(torqueByNode[node.id])
            totalLoad = totalLoad + node.dynamicLoad
        end
    end

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
                if gear.gearType ~= "lubricant"
                    and (gear.lubricationRemaining or 0) <= 0
                    and not lubricationAvailable then
                    maintenanceJammed = true
                end
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
                    lubricationByLayer[depth]
                        or (
                            lubricationAvailable
                            and GearDefinitions.Revenue.lubricant.lubricationLoadMultiplier
                            or 1
                        )
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

    jammed = jammed or maintenanceJammed
    for _, conflict in ipairs(conflictPairs) do
        if type(conflict.a) == "number" and conflict.a > 0
            and gears[conflict.a] then
            gears[conflict.a].localJammed = true
        end
        if type(conflict.b) == "number" and conflict.b > 0
            and gears[conflict.b] then
            gears[conflict.b].localJammed = true
        end
    end
    if maintenanceJammed then
        for index, gear in ipairs(gears) do
            if gear.gearType ~= "lubricant"
                and directionByNode[index] ~= nil
                and (gear.lubricationRemaining or 0) <= 0 then
                gear.localJammed = true
            end
        end
    end
    local overloaded = not jammed
        and sourcePowered
        and totalLoad > sourceTorque

    for _, gear in ipairs(gears) do
        if gear.gearType == "lubricant" then
            local definition = GearDefinitions.Get("lubricant")
            gear.connected = (gear.lubricationRemaining or 0) > 0
            gear.meshed = true
            gear.jammed = false
            gear.localJammed = false
            gear.overloaded = false
            gear.spinDirection = 1
            gear.rpm = gear.connected and definition.autonomousRPM or 0
            gear.rpmRatio = 0
            gear.torque = 0
            gear.incomePerSecond = 0
            gear.load = 0
            gear.layerSpeedFactor = 1
            gear.transmissionDepth = 0
            gear.parentIndex = nil
            gear.inputRing = nil
            gear.lubricated = lubricationAvailable
            gear.lubricationSource = gear.id == lubricationSourceGearId
            gear.maintenanceJammed = false
            if gear.connected then
                connectedCount = connectedCount + 1
            end
        end
    end

    if sourcePowered and not jammed and not overloaded then
        totalIncomePerSecond = 0
        for index, gear in ipairs(gears) do
            if directionByNode[index] ~= nil then
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
                gear.lubricated = lubricationAvailable
                gear.lubricationSource = gear.id == lubricationSourceGearId
                gear.maintenanceJammed = false
                gear.torque = assert(torqueByNode[index])
                gear.incomePerSecond = 0
                connectedCount = connectedCount + 1
            end
        end
    else
        for index, gear in ipairs(gears) do
            if gear.gearType ~= "lubricant" then
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
                    gear.lubricated = lubricationAvailable
                    gear.lubricationSource = false
                    gear.maintenanceJammed = maintenanceJammed
                        and (gear.lubricationRemaining or 0) <= 0
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
    end

    for _, node in ipairs(externalNodes) do
        if node.connected then
            local rpm = assert(rpmByNode[node.id])
            for layer = 1, node.transmissionDepth do
                rpm = rpm * (speedFactorByLayer[layer] or 1)
            end
            node.jammed = jammed
            node.overloaded = overloaded
            node.powered = sourcePowered
                and node.assetUnlocked ~= false
                and not jammed
                and not overloaded
                and node.torque >= math.max(0, node.requiredTorque or 0)
                and rpm > 0
            node.rpm = node.powered
                and math.min(rpm, GearDefinitions.Main.maxRPM)
                or 0
            if node.assetUnlocked == false then
                node.status = "assetLocked"
            elseif jammed then
                node.status = "jammed"
            elseif overloaded then
                node.status = "overloaded"
            elseif not sourcePowered then
                node.status = "sourceOff"
            elseif node.torque < math.max(0, node.requiredTorque or 0) then
                node.status = "insufficientTorque"
            elseif node.powered then
                node.status = "running"
            else
                node.status = "isolated"
            end
        elseif node.meshed then
            node.status = "isolated"
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
        transmissionJammed = transmissionJammed,
        maintenanceJammed = maintenanceJammed,
        lubricationActive = lubricationAvailable,
        lubricationSourceGearId = lubricationSourceGearId,
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
        externalNodes = externalById,
    }
end

return GearSystem
