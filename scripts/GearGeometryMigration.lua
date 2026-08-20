local GearDefinitions = require("GearDefinitions")

local GearGeometryMigration = {}

local LEGACY_GEOMETRY_VERSION = 1
local LEGACY_MESH_TOLERANCE = 0.12
local RING_ORDER = { "outer", "inner" }

local LEGACY_GEARS = {
    main = {
        outerRadius = 1.0,
        rings = {
            outer = { teeth = 32, radiusScale = 1.0 },
            inner = { teeth = 12, radiusScale = 0.375 },
        },
    },
    small = {
        outerRadius = 0.5,
        rings = {
            outer = { teeth = 16, radiusScale = 1.0 },
        },
    },
    medium = {
        outerRadius = 1.0,
        rings = {
            outer = { teeth = 32, radiusScale = 1.0 },
        },
    },
    large = {
        outerRadius = 1.5,
        rings = {
            outer = { teeth = 48, radiusScale = 1.0 },
        },
    },
    large_compound = {
        outerRadius = 1.5,
        rings = {
            outer = { teeth = 48, radiusScale = 1.0 },
            inner = { teeth = 16, radiusScale = 1 / 3 },
        },
    },
    compound = {
        outerRadius = 1.0,
        rings = {
            outer = { teeth = 32, radiusScale = 1.0 },
            inner = { teeth = 12, radiusScale = 0.375 },
        },
    },
    momma = {
        outerRadius = 1.5,
        rings = {
            outer = { teeth = 48, radiusScale = 1.0 },
            inner = { teeth = 16, radiusScale = 1 / 3 },
        },
    },
}

local function Distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function GetLegacyDefinition(gearType)
    return LEGACY_GEARS[gearType] or LEGACY_GEARS.small
end

local function GetCurrentOuterRadius(gearType)
    if gearType == "main" then
        return 1.0
    end
    return GearDefinitions.Get(gearType).radiusScale
end

local function GetCurrentRingRadius(gearType, ringName)
    local rings = GearDefinitions.GetRings(gearType)
    local ring = rings[ringName]
    if not ring then
        return nil
    end
    return GetCurrentOuterRadius(gearType) * ring.radiusScale
end

local function FindLegacyMesh(first, second)
    local firstDefinition = GetLegacyDefinition(first.gearType)
    local secondDefinition = GetLegacyDefinition(second.gearType)
    local distance = Distance(first.x, first.y, second.x, second.y)
    local best = nil

    for _, firstRingName in ipairs(RING_ORDER) do
        local firstRing = firstDefinition.rings[firstRingName]
        if firstRing then
            for _, secondRingName in ipairs(RING_ORDER) do
                local secondRing = secondDefinition.rings[secondRingName]
                if secondRing then
                    local targetDistance =
                        firstDefinition.outerRadius * firstRing.radiusScale
                        + secondDefinition.outerRadius * secondRing.radiusScale
                    local error = math.abs(distance - targetDistance)
                    if error <= LEGACY_MESH_TOLERANCE
                        and (best == nil or error < best.error) then
                        best = {
                            error = error,
                            firstRing = firstRingName,
                            secondRing = secondRingName,
                        }
                    end
                end
            end
        end
    end

    return best
end

local function AddEdge(adjacency, firstIndex, secondIndex, mesh)
    local edge = {
        first = firstIndex,
        second = secondIndex,
        firstRing = mesh.firstRing,
        secondRing = mesh.secondRing,
    }
    adjacency[firstIndex][#adjacency[firstIndex] + 1] = edge
    adjacency[secondIndex][#adjacency[secondIndex] + 1] = edge
end

local function ResolveNewDistance(edge, currentIndex, nodes)
    local firstRadius = GetCurrentRingRadius(
        nodes[edge.first].gearType,
        edge.firstRing
    )
    local secondRadius = GetCurrentRingRadius(
        nodes[edge.second].gearType,
        edge.secondRing
    )
    if firstRadius == nil or secondRadius == nil then
        return nil
    end
    return firstRadius + secondRadius
end

local function PlaceConnectedComponent(rootIndex, nodes, adjacency, placed)
    local queue = { rootIndex }
    local head = 1
    placed[rootIndex] = true
    local preservedEdges = 0

    while head <= #queue do
        local currentIndex = queue[head]
        head = head + 1
        local current = nodes[currentIndex]
        for _, edge in ipairs(adjacency[currentIndex]) do
            local neighborIndex = edge.first == currentIndex
                    and edge.second
                or edge.first
            if not placed[neighborIndex] then
                local neighbor = nodes[neighborIndex]
                local oldDx = neighbor.oldX - current.oldX
                local oldDy = neighbor.oldY - current.oldY
                local oldDistance = math.sqrt(oldDx * oldDx + oldDy * oldDy)
                local directionX = 1
                local directionY = 0
                if oldDistance > 0.0001 then
                    directionX = oldDx / oldDistance
                    directionY = oldDy / oldDistance
                end
                local newDistance = ResolveNewDistance(
                    edge,
                    currentIndex,
                    nodes
                )
                if newDistance then
                    neighbor.x = current.x + directionX * newDistance
                    neighbor.y = current.y + directionY * newDistance
                    placed[neighborIndex] = true
                    queue[#queue + 1] = neighborIndex
                    preservedEdges = preservedEdges + 1
                end
            end
        end
    end

    return preservedEdges
end

function GearGeometryMigration.Migrate(gameData)
    local sourceVersion = math.max(
        LEGACY_GEOMETRY_VERSION,
        gameData.geometryVersion or LEGACY_GEOMETRY_VERSION
    )
    if sourceVersion >= GearDefinitions.GeometryVersion then
        gameData.geometryVersion = GearDefinitions.GeometryVersion
        return false, 0
    end
    if sourceVersion >= 2 then
        gameData.geometryVersion = GearDefinitions.GeometryVersion
        print(string.format(
            "[GearGeometryMigration] 齿数规格升级完成: version=%d->%d, 布局尺寸不变",
            sourceVersion,
            GearDefinitions.GeometryVersion
        ))
        return true, 0
    end

    local nodes = {
        [0] = {
            gearType = "main",
            x = 0,
            y = 0,
            oldX = 0,
            oldY = 0,
        },
    }
    local adjacency = { [0] = {} }
    local migratableCount = 0

    for index, gear in ipairs(gameData.revenueGears or {}) do
        if type(gear.anchorX) == "number"
            and type(gear.anchorY) == "number" then
            nodes[index] = {
                gear = gear,
                gearType = gear.gearType,
                x = gear.anchorX,
                y = gear.anchorY,
                oldX = gear.anchorX,
                oldY = gear.anchorY,
            }
            adjacency[index] = {}
            migratableCount = migratableCount + 1
        end
    end

    local totalGearCount = #(gameData.revenueGears or {})
    if migratableCount < totalGearCount then
        print(string.format(
            "[GearGeometryMigration] 等待布局建立旧坐标锚点: ready=%d/%d",
            migratableCount,
            totalGearCount
        ))
        return false, 0
    end

    for firstIndex = 0, totalGearCount do
        local first = nodes[firstIndex]
        if first then
            for secondIndex = firstIndex + 1, #gameData.revenueGears do
                local second = nodes[secondIndex]
                if second then
                    local mesh = FindLegacyMesh(first, second)
                    if mesh then
                        AddEdge(adjacency, firstIndex, secondIndex, mesh)
                    end
                end
            end
        end
    end

    local placed = {}
    local preservedEdges = PlaceConnectedComponent(
        0,
        nodes,
        adjacency,
        placed
    )

    for index = 1, #gameData.revenueGears do
        local node = nodes[index]
        if node and not placed[index] then
            local oldDefinition = GetLegacyDefinition(node.gearType)
            local radialDistance = math.sqrt(
                node.oldX * node.oldX + node.oldY * node.oldY
            )
            local outwardOffset = math.max(
                0,
                GetCurrentOuterRadius(node.gearType)
                    - oldDefinition.outerRadius
            )
            if radialDistance > 0.0001 then
                node.x = node.oldX
                    + node.oldX / radialDistance * outwardOffset
                node.y = node.oldY
                    + node.oldY / radialDistance * outwardOffset
            end
            preservedEdges = preservedEdges + PlaceConnectedComponent(
                index,
                nodes,
                adjacency,
                placed
            )
        end
    end

    for index, node in pairs(nodes) do
        if index > 0 and node.gear then
            node.gear.anchorX = node.x
            node.gear.anchorY = node.y
        end
    end

    gameData.geometryVersion = GearDefinitions.GeometryVersion
    print(string.format(
        "[GearGeometryMigration] 几何规格迁移完成: version=%d->%d, gears=%d, preservedEdges=%d",
        sourceVersion,
        GearDefinitions.GeometryVersion,
        migratableCount,
        preservedEdges
    ))
    return true, preservedEdges
end

return GearGeometryMigration
