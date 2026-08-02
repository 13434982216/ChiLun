local GearDefinitions = require("GearDefinitions")

local GearRenderer = {}

local gearImages_ = {}
local initialized_ = false
local IMAGE_CONTENT_DIAMETER_RATIO = 460 / 512

local IMAGE_PATHS = {
    main = "image/gear_main_comic_exact.png",
    small = "image/gear_small_comic_exact.png",
    medium = "image/gear_medium_comic_exact.png",
    large = "image/gear_large_comic_exact.png",
    compound = "image/gear_compound_comic_exact.png",
    momma = "image/gear_momma_comic_exact.png",
}

function GearRenderer.Initialize(vg)
    if initialized_ then
        return
    end

    for gearType, path in pairs(IMAGE_PATHS) do
        gearImages_[gearType] = nvgCreateImage(vg, path, 0)
        print(string.format(
            "[GearRenderer] 漫画齿轮图片已加载: type=%s, handle=%s, path=%s",
            gearType,
            tostring(gearImages_[gearType]),
            path
        ))
    end
    initialized_ = true
end

local function DrawGearImage(vg, image, pitchRadius, teeth, alpha)
    if not image or image <= 0 then
        return
    end

    local addendumScale = 1 + 2 / math.max(1, teeth)
    local visualTipRadius = pitchRadius * addendumScale
    local size = visualTipRadius * 2 / IMAGE_CONTENT_DIAMETER_RATIO
    local origin = -size * 0.5
    nvgBeginPath(vg)
    nvgRect(vg, origin, origin, size, size)
    nvgFillPaint(vg, nvgImagePattern(
        vg,
        origin,
        origin,
        size,
        size,
        0,
        image,
        alpha or 1
    ))
    nvgFill(vg)
end

local function DrawStatusGlow(vg, x, y, radius, color)
    local glow = nvgRadialGradient(
        vg,
        x,
        y,
        radius * 0.5,
        radius * 1.4,
        color,
        nvgRGBA(0, 0, 0, 0)
    )
    nvgBeginPath(vg)
    nvgCircle(vg, x, y, radius * 1.4)
    nvgFillPaint(vg, glow)
    nvgFill(vg)
end

local function DrawSelectionRing(vg, radius, color, width)
    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, radius * 1.07)
    nvgStrokeColor(vg, nvgRGBA(8, 13, 18, 225))
    nvgStrokeWidth(vg, width + 3)
    nvgStroke(vg)

    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, radius * 1.07)
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

local function FindConnection(connections, firstIndex, secondIndex)
    for _, connection in ipairs(connections) do
        if (connection.a == firstIndex and connection.b == secondIndex)
            or (connection.a == secondIndex and connection.b == firstIndex) then
            return connection
        end
    end
    return nil
end

function GearRenderer.ResolveVisualAngles(
    gears,
    connections,
    mainX,
    mainY,
    mainAngle
)
    ---@type table<integer, number>
    local visualAngles = { [0] = mainAngle }

    for _ = 1, #gears + 1 do
        local resolvedThisPass = 0
        for index, gear in ipairs(gears) do
            if visualAngles[index] == nil and gear.parentIndex ~= nil then
                local parentIndex = gear.parentIndex
                local parentAngle = visualAngles[parentIndex]
                local connection = parentAngle ~= nil
                    and FindConnection(connections, parentIndex, index)
                    or nil
                if connection then
                    local parentX, parentY = mainX, mainY
                    if parentIndex > 0 then
                        parentX = gears[parentIndex].x
                        parentY = gears[parentIndex].y
                    end
                    local contactAngle = math.atan(
                        gear.y - parentY,
                        gear.x - parentX
                    )
                    local parentTeeth = connection.a == parentIndex
                        and connection.aTeeth
                        or connection.bTeeth
                    local childTeeth = connection.a == index
                        and connection.aTeeth
                        or connection.bTeeth
                    local toothRatio = parentTeeth / childTeeth
                    visualAngles[index] =
                        (1 + toothRatio) * contactAngle
                        + math.pi
                        + math.pi / childTeeth
                        - toothRatio * parentAngle
                    resolvedThisPass = resolvedThisPass + 1
                end
            end
        end
        if resolvedThisPass == 0 then
            break
        end
    end

    for index, gear in ipairs(gears) do
        visualAngles[index] = visualAngles[index] or gear.angle
    end
    return visualAngles
end

function GearRenderer.GetLayeredGearIndices(gears, draggedIndex)
    local indices = {}
    for index = 1, #gears do
        if index ~= draggedIndex then
            indices[#indices + 1] = index
        end
    end
    table.sort(indices, function(a, b)
        local first = gears[a]
        local second = gears[b]
        if first.transmissionDepth ~= second.transmissionDepth then
            return first.transmissionDepth < second.transmissionDepth
        end
        if first.y ~= second.y then
            return first.y < second.y
        end
        return first.id < second.id
    end)
    return indices
end

function GearRenderer.DrawBackground(vg, width, height, mainX, mainY, mainRadius)
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, width, height)
    nvgFillPaint(vg, nvgLinearGradient(
        vg,
        0,
        0,
        0,
        height,
        nvgRGBA(31, 48, 61, 255),
        nvgRGBA(10, 20, 29, 255)
    ))
    nvgFill(vg)

    local minorGrid = 24
    nvgBeginPath(vg)
    for x = mainX % minorGrid, width, minorGrid do
        nvgMoveTo(vg, x, 0)
        nvgLineTo(vg, x, height)
    end
    for y = mainY % minorGrid, height, minorGrid do
        nvgMoveTo(vg, 0, y)
        nvgLineTo(vg, width, y)
    end
    nvgStrokeColor(vg, nvgRGBA(86, 148, 174, 34))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)

    local majorGrid = minorGrid * 5
    nvgBeginPath(vg)
    for x = mainX % majorGrid, width, majorGrid do
        nvgMoveTo(vg, x, 0)
        nvgLineTo(vg, x, height)
    end
    for y = mainY % majorGrid, height, majorGrid do
        nvgMoveTo(vg, 0, y)
        nvgLineTo(vg, width, y)
    end
    nvgStrokeColor(vg, nvgRGBA(112, 188, 211, 65))
    nvgStrokeWidth(vg, 1.4)
    nvgStroke(vg)

    for ring = 2, 5 do
        nvgBeginPath(vg)
        nvgCircle(vg, mainX, mainY, mainRadius * ring * 0.75)
        nvgStrokeColor(vg, nvgRGBA(122, 195, 210, ring == 2 and 60 or 28))
        nvgStrokeWidth(vg, ring == 2 and 1.5 or 1)
        nvgStroke(vg)
    end

    nvgBeginPath(vg)
    nvgMoveTo(vg, mainX - mainRadius * 4, mainY)
    nvgLineTo(vg, mainX + mainRadius * 4, mainY)
    nvgMoveTo(vg, mainX, mainY - mainRadius * 4)
    nvgLineTo(vg, mainX, mainY + mainRadius * 4)
    nvgStrokeColor(vg, nvgRGBA(158, 215, 224, 52))
    nvgStrokeWidth(vg, 1)
    nvgStroke(vg)
end

function GearRenderer.DrawConnections(vg, connections, gears, mainX, mainY)
    for _, connection in ipairs(connections) do
        local firstX, firstY = mainX, mainY
        if connection.a > 0 then
            firstX = gears[connection.a].x
            firstY = gears[connection.a].y
        end
        local secondX, secondY = mainX, mainY
        if connection.b > 0 then
            secondX = gears[connection.b].x
            secondY = gears[connection.b].y
        end

        local color = connection.meshed
            and nvgRGBA(255, 190, 71, 120)
            or nvgRGBA(111, 149, 165, 42)
        if connection.conflict then
            color = nvgRGBA(255, 74, 68, 230)
        elseif connection.powered then
            color = nvgRGBA(72, 230, 148, 130)
        end

        nvgBeginPath(vg)
        nvgMoveTo(vg, firstX, firstY)
        nvgLineTo(vg, secondX, secondY)
        nvgStrokeColor(vg, nvgRGBA(4, 9, 14, 205))
        nvgStrokeWidth(vg, connection.conflict and 7 or 5)
        nvgStroke(vg)

        nvgBeginPath(vg)
        nvgMoveTo(vg, firstX, firstY)
        nvgLineTo(vg, secondX, secondY)
        nvgStrokeColor(vg, color)
        nvgStrokeWidth(vg, connection.conflict and 3.5 or 2)
        nvgStroke(vg)
    end
end

function GearRenderer.DrawFactory(
    vg,
    x,
    y,
    width,
    height,
    unlocked,
    running,
    stock,
    maxStock,
    progress,
    warningPhase
)
    if unlocked and running then
        local pulse = 0.55 + 0.45 * math.sin((warningPhase or 0) * 4)
        local glow = nvgRadialGradient(
            vg,
            x,
            y,
            width * 0.15,
            width * 0.85,
            nvgRGBA(57, 241, 145, math.floor(55 + pulse * 65)),
            nvgRGBA(0, 0, 0, 0)
        )
        nvgBeginPath(vg)
        nvgEllipse(vg, x, y, width * 0.9, height * 1.15)
        nvgFillPaint(vg, glow)
        nvgFill(vg)
    end

    local left = x - width * 0.5
    local top = y - height * 0.5
    nvgBeginPath(vg)
    nvgRoundedRect(vg, left, top, width, height, 10)
    nvgFillColor(vg, unlocked
        and nvgRGBA(24, 51, 50, 245)
        or nvgRGBA(37, 43, 48, 225))
    nvgFill(vg)
    nvgStrokeColor(vg, unlocked
        and nvgRGBA(87, 218, 155, 235)
        or nvgRGBA(105, 116, 123, 190))
    nvgStrokeWidth(vg, 2.5)
    nvgStroke(vg)

    for index = 0, 2 do
        local towerX = left + 18 + index * 22
        nvgBeginPath(vg)
        nvgRect(vg, towerX, top - 15 - index * 4, 13, 24 + index * 4)
        nvgFillColor(vg, nvgRGBA(48, 66, 70, 255))
        nvgFill(vg)
        nvgStrokeColor(vg, nvgRGBA(10, 18, 21, 230))
        nvgStrokeWidth(vg, 2)
        nvgStroke(vg)
    end

    local lampColor = unlocked and running
        and nvgRGBA(71, 247, 153, 255)
        or nvgRGBA(104, 113, 117, 255)
    nvgBeginPath(vg)
    nvgCircle(vg, left + width - 17, top + 17, 6)
    nvgFillColor(vg, lampColor)
    nvgFill(vg)

    local barLeft = left + 12
    local barTop = top + height - 20
    local barWidth = width - 24
    nvgBeginPath(vg)
    nvgRoundedRect(vg, barLeft, barTop, barWidth, 8, 4)
    nvgFillColor(vg, nvgRGBA(9, 20, 22, 235))
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, barLeft, barTop, barWidth * math.max(0, math.min(1, progress)), 8, 4)
    nvgFillColor(vg, lampColor)
    nvgFill(vg)

    for index = 1, maxStock do
        local stockX = left + 14 + (index - 1) * 15
        nvgBeginPath(vg)
        nvgCircle(vg, stockX, top + height - 33, 5)
        nvgFillColor(vg, index <= stock
            and nvgRGBA(255, 190, 62, 255)
            or nvgRGBA(72, 82, 84, 220))
        nvgFill(vg)
    end
end

function GearRenderer.DrawMainGear(
    vg,
    x,
    y,
    radius,
    angle,
    pulse,
    isPowered,
    isSpeedCapped,
    warningPhase
)
    local pulseScale = 1 + pulse * 0.045
    if isPowered then
        DrawStatusGlow(vg, x, y, radius, nvgRGBA(255, 192, 53, 100))
    end

    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgScale(vg, pulseScale, pulseScale)
    nvgRotate(vg, angle)
    DrawGearImage(
        vg,
        gearImages_.main,
        radius,
        GearDefinitions.Main.rings.outer.teeth,
        isPowered and 1 or 0.82
    )
    nvgRestore(vg)

    if isSpeedCapped then
        local flash = 0.5 + 0.5 * math.sin((warningPhase or 0) * 9)
        nvgBeginPath(vg)
        nvgCircle(vg, x, y, radius * 1.12)
        nvgStrokeColor(vg, nvgRGBA(255, 43, 43, math.floor(125 + flash * 130)))
        nvgStrokeWidth(vg, 4 + flash * 3)
        nvgStroke(vg)
    end
end

function GearRenderer.DrawRevenueGear(
    vg,
    gear,
    isDragging,
    isSelected,
    visualAngle,
    placementValid
)
    local radius = gear.radius
    local visualRadius = radius * (1 + 2 / math.max(1, gear.teeth))
    if gear.connected then
        DrawStatusGlow(vg, gear.x, gear.y, radius, nvgRGBA(62, 232, 143, 90))
    elseif gear.meshed then
        DrawStatusGlow(vg, gear.x, gear.y, radius, nvgRGBA(255, 185, 55, 52))
    end

    nvgSave(vg)
    nvgTranslate(vg, gear.x, gear.y)
    nvgRotate(vg, visualAngle or gear.angle)
    if gear.gearType == "large_compound" then
        DrawGearImage(
            vg,
            gearImages_.large,
            radius,
            GearDefinitions.GetRings("large_compound").outer.teeth,
            gear.jammed and 0.68 or 1
        )
        DrawGearImage(
            vg,
            gearImages_.small,
            radius * GearDefinitions.GetRings("large_compound").inner.radiusScale,
            GearDefinitions.GetRings("large_compound").inner.teeth,
            gear.jammed and 0.72 or 1
        )
    else
        DrawGearImage(
            vg,
            gearImages_[gear.gearType],
            radius,
            gear.teeth,
            gear.jammed and 0.68 or 1
        )
    end

    if gear.jammed then
        DrawSelectionRing(vg, visualRadius, nvgRGBA(255, 70, 65, 255), 3.5)
    elseif isDragging and placementValid == false then
        DrawSelectionRing(vg, visualRadius, nvgRGBA(255, 62, 57, 255), 4)
        nvgRotate(vg, -(visualAngle or gear.angle))
        nvgBeginPath(vg)
        nvgMoveTo(vg, -radius * 0.34, -radius * 0.34)
        nvgLineTo(vg, radius * 0.34, radius * 0.34)
        nvgMoveTo(vg, radius * 0.34, -radius * 0.34)
        nvgLineTo(vg, -radius * 0.34, radius * 0.34)
        nvgStrokeColor(vg, nvgRGBA(255, 72, 66, 245))
        nvgStrokeWidth(vg, math.max(4, radius * 0.08))
        nvgStroke(vg)
    elseif isDragging then
        DrawSelectionRing(vg, visualRadius, nvgRGBA(71, 204, 255, 255), 3.5)
    end
    nvgRestore(vg)
end

return GearRenderer
