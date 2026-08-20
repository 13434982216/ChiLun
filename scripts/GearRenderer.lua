local GearDefinitions = require("GearDefinitions")
local GearSystem = require("GearSystem")

local GearRenderer = {}

local currencyGeneratorBodyImage_ = 0
local currencyGeneratorAnimationImages_ = {}
local powerGeneratorAnimationImages_ = {}
local powerGeneratorIdleImage_ = 0
local powerGeneratorGearImage_ = 0
local clockAnimationImages_ = {}
local clockIdleImage_ = 0
local miningMachineImage_ = 0
local miningMachineAnimationImages_ = {}
local gearImageHandlesByContext_ = {}
local GEAR_IMAGE_PATHS = {
    main = "image/gear_main_comic_exact.png",
    small = "image/gear_small_comic_exact.png",
    medium = "image/gear_medium_comic_exact.png",
    large = "image/gear_large_comic_exact.png",
    large_compound = "image/gear_large_comic_exact.png",
    compound = "image/gear_compound_comic_exact.png",
    coin = "image/gear_coin_large_comic_20260811093509.png",
    momma = "image/gear_momma_comic_exact.png",
}
local GEAR_IMAGE_RADIUS_FACTORS = {
    main = 0.908004,
    small = 0.908004,
    medium = 0.908961,
    large = 0.908676,
    large_compound = 0.908676,
    compound = 0.908961,
    coin = 0.878906,
    momma = 0.908457,
}
local incomeFont_ = -1
local CURRENCY_GENERATOR_FRAME_COUNT = 48
local CURRENCY_GENERATOR_ANIMATION_FPS = 8
local POWER_GENERATOR_FRAME_COUNT = 48
local POWER_GENERATOR_ANIMATION_FPS = 12
local CLOCK_RUNNING_FRAME_COUNT = 97
local CLOCK_RUNNING_ANIMATION_FPS = 12
local MINING_MACHINE_FRAME_COUNT = 48
local MINING_MACHINE_ANIMATION_FPS = 6
local initialized_ = false

local GEAR_PALETTES = {
    main = {
        primary = { 194, 142, 45, 255 },
        highlight = { 232, 195, 103, 255 },
        shade = { 104, 68, 24, 255 },
        edge = { 31, 28, 23, 255 },
        spoke = { 162, 108, 34, 255 },
    },
    mainInner = {
        primary = { 166, 115, 38, 255 },
        highlight = { 213, 173, 86, 255 },
        shade = { 83, 54, 24, 255 },
        edge = { 31, 28, 23, 255 },
        spoke = { 135, 88, 31, 255 },
    },
    small = {
        primary = { 91, 115, 126, 255 },
        highlight = { 151, 169, 174, 255 },
        shade = { 45, 60, 67, 255 },
        edge = { 25, 29, 30, 255 },
        spoke = { 72, 92, 101, 255 },
    },
    medium = {
        primary = { 105, 114, 88, 255 },
        highlight = { 163, 169, 133, 255 },
        shade = { 53, 60, 45, 255 },
        edge = { 26, 29, 24, 255 },
        spoke = { 81, 91, 68, 255 },
    },
    large = {
        primary = { 76, 86, 94, 255 },
        highlight = { 135, 146, 151, 255 },
        shade = { 35, 42, 47, 255 },
        edge = { 21, 24, 26, 255 },
        spoke = { 58, 67, 73, 255 },
    },
    compoundOuter = {
        primary = { 154, 72, 48, 255 },
        highlight = { 203, 124, 83, 255 },
        shade = { 82, 38, 29, 255 },
        edge = { 34, 25, 22, 255 },
        spoke = { 126, 55, 39, 255 },
    },
    compoundInner = {
        primary = { 74, 103, 112, 255 },
        highlight = { 135, 158, 162, 255 },
        shade = { 35, 52, 58, 255 },
        edge = { 23, 28, 30, 255 },
        spoke = { 57, 81, 88, 255 },
    },
    momma = {
        primary = { 111, 74, 52, 255 },
        highlight = { 169, 123, 87, 255 },
        shade = { 57, 38, 29, 255 },
        edge = { 28, 24, 21, 255 },
        spoke = { 87, 57, 42, 255 },
    },
    mommaInner = {
        primary = { 174, 126, 46, 255 },
        highlight = { 220, 181, 94, 255 },
        shade = { 90, 61, 25, 255 },
        edge = { 31, 27, 22, 255 },
        spoke = { 142, 95, 33, 255 },
    },
    lubricant = {
        primary = { 29, 157, 139, 255 },
        highlight = { 116, 240, 206, 255 },
        shade = { 13, 72, 72, 255 },
        edge = { 12, 38, 43, 255 },
        spoke = { 24, 116, 108, 255 },
    },
}

function GearRenderer.Initialize(vg)
    if initialized_ then
        return
    end

    incomeFont_ = nvgCreateFont(
        vg,
        "income-bold",
        "Fonts/NotoSansCJKsc-Regular.otf"
    )
    print(string.format(
        "[GearRenderer] 收益数字字体已加载: handle=%s",
        tostring(incomeFont_)
    ))
    print(string.format(
        "[GearRenderer] 使用程序化精确齿形: geometryVersion=%d, module=%d齿/主齿轮半径",
        GearDefinitions.GeometryVersion,
        GearDefinitions.TeethPerMainRadius
    ))

    currencyGeneratorBodyImage_ = nvgCreateImage(
        vg,
        "image/currency_generator_body_comic.png",
        0
    )
    print(string.format(
        "[GearRenderer] 漫画货币生成器机身已加载: handle=%s",
        tostring(currencyGeneratorBodyImage_)
    ))
    for frame = 1, CURRENCY_GENERATOR_FRAME_COUNT do
        currencyGeneratorAnimationImages_[frame] = nvgCreateImage(
            vg,
            string.format(
                "image/currency_generator_frames/frame_%02d.png",
                frame
            ),
            0
        )
    end
    print(string.format(
        "[GearRenderer] 货币生成器序列帧已加载: frames=%d, fps=%d",
        CURRENCY_GENERATOR_FRAME_COUNT,
        CURRENCY_GENERATOR_ANIMATION_FPS
    ))
    for frame = 1, POWER_GENERATOR_FRAME_COUNT do
        powerGeneratorAnimationImages_[frame] = nvgCreateImage(
            vg,
            string.format(
                "image/power_generator_frames/power_generator_%03d.png",
                frame
            ),
            0
        )
    end
    print(string.format(
        "[GearRenderer] 独立发电机序列帧已加载: frames=%d, fps=%d",
        POWER_GENERATOR_FRAME_COUNT,
        POWER_GENERATOR_ANIMATION_FPS
    ))
    powerGeneratorIdleImage_ = nvgCreateImage(
        vg,
        "image/power_generator_idle_clean_trimmed.png",
        0
    )
    print(string.format(
        "[GearRenderer] 发电机停机图已加载: handle=%s",
        tostring(powerGeneratorIdleImage_)
    ))
    for frame = 1, CLOCK_RUNNING_FRAME_COUNT do
        clockAnimationImages_[frame] = nvgCreateImage(
            vg,
            string.format(
                "image/clock_running_frames/frame_%03d.png",
                frame
            ),
            0
        )
    end
    clockIdleImage_ = clockAnimationImages_[1]
    print(string.format(
        "[GearRenderer] 独立钟表序列帧已加载: frames=%d, fps=%d",
        CLOCK_RUNNING_FRAME_COUNT,
        CLOCK_RUNNING_ANIMATION_FPS
    ))
    powerGeneratorGearImage_ = nvgCreateImage(
        vg,
        "image/power_generator_mesh_gear_exact_20260806045922.png",
        0
    )
    print(string.format(
        "[GearRenderer] 发电机传动齿轮已加载: handle=%s",
        tostring(powerGeneratorGearImage_)
    ))
    miningMachineImage_ = nvgCreateImage(
        vg,
        "image/mechanical_mining_machine_comic_20260809082218.png",
        0
    )
    print(string.format(
        "[GearRenderer] 扭矩矿机机身已加载: handle=%s",
        tostring(miningMachineImage_)
    ))
    for frame = 1, MINING_MACHINE_FRAME_COUNT do
        miningMachineAnimationImages_[frame] = nvgCreateImage(
            vg,
            string.format(
                "image/mining_machine_working_frames/frame_%02d.png",
                frame
            ),
            0
        )
    end
    print(string.format(
        "[GearRenderer] 矿机工作序列帧已加载: frames=%d, fps=%d",
        MINING_MACHINE_FRAME_COUNT,
        MINING_MACHINE_ANIMATION_FPS
    ))
    initialized_ = true
end

local function WithAlpha(color, alpha)
    return nvgRGBA(
        color[1],
        color[2],
        color[3],
        math.floor(color[4] * math.max(0, math.min(1, alpha or 1)))
    )
end

local function GetGearImageHandle(vg, gearType)
    local contextKey = tostring(vg)
    local handles = gearImageHandlesByContext_[contextKey]
    if not handles then
        handles = {}
        gearImageHandlesByContext_[contextKey] = handles
    end

    local resolvedType = gearType == "large_compound"
        and "large"
        or gearType
    local existing = handles[resolvedType]
    if existing and existing > 0 then
        return existing
    end

    local imagePath = GEAR_IMAGE_PATHS[resolvedType]
    if not imagePath then
        return 0
    end

    local handle = nvgCreateImage(vg, imagePath, 0)
    if handle and handle > 0 then
        handles[resolvedType] = handle
        print(string.format(
            "[GearRenderer] 工业漫画齿轮 PNG 已加载: type=%s, handle=%s, path=%s",
            resolvedType,
            tostring(handle),
            imagePath
        ))
    else
        handles[resolvedType] = nil
        print(string.format(
            "[GearRenderer] ERROR: 齿轮 PNG 加载失败，将在下一帧重试: type=%s, path=%s",
            resolvedType,
            imagePath
        ))
    end
    return handle
end

local function DrawGearImage(
    vg,
    gearType,
    x,
    y,
    imageSize,
    alpha,
    angle
)
    local imageHandle = GetGearImageHandle(vg, gearType)
    if not imageHandle or imageHandle <= 0 then
        return false
    end

    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, angle or 0)
    local imageLeft = -imageSize * 0.5
    local imageTop = -imageSize * 0.5
    nvgBeginPath(vg)
    nvgRect(vg, imageLeft, imageTop, imageSize, imageSize)
    nvgFillPaint(vg, nvgImagePattern(
        vg,
        imageLeft,
        imageTop,
        imageSize,
        imageSize,
        0,
        imageHandle,
        math.max(0, math.min(1, alpha or 1))
    ))
    nvgFill(vg)
    nvgRestore(vg)
    return true
end

local function DrawProceduralGear(
    vg,
    pitchRadius,
    teeth,
    palette,
    alpha,
    spokeCount,
    visualStyle
)
    local safeTeeth = math.max(6, math.floor(teeth or 6))
    local step = math.pi * 2 / safeTeeth
    local profile = GearDefinitions.GearProfile
    local rootRadius = GearDefinitions.GetRootRadius(
        pitchRadius,
        safeTeeth
    )
    local tipRadius = GearDefinitions.GetTipRadius(
        pitchRadius,
        safeTeeth
    )
    local pitchShoulderRadius = pitchRadius
    local style = visualStyle or "classic"
    alpha = alpha or 1

    -- 共享模数的直齿漫画轮廓：齿顶高 1.0m、齿根高 1.25m，
    -- 相邻节圆相切时保留 0.25m 顶隙，避免视觉穿插。
    nvgBeginPath(vg)
    for tooth = 0, safeTeeth - 1 do
        local centerAngle = tooth * step
        local points = {
            { centerAngle - step * 0.50, rootRadius },
            { centerAngle - step * profile.rootHalfWidth, rootRadius },
            { centerAngle - step * profile.pitchHalfWidth, pitchShoulderRadius },
            { centerAngle - step * profile.tipHalfWidth, tipRadius },
            { centerAngle + step * profile.tipHalfWidth, tipRadius },
            { centerAngle + step * profile.pitchHalfWidth, pitchShoulderRadius },
            { centerAngle + step * profile.rootHalfWidth, rootRadius },
            { centerAngle + step * 0.50, rootRadius },
        }
        for pointIndex, point in ipairs(points) do
            local px = math.sin(point[1]) * point[2]
            local py = -math.cos(point[1]) * point[2]
            if tooth == 0 and pointIndex == 1 then
                nvgMoveTo(vg, px, py)
            else
                nvgLineTo(vg, px, py)
            end
        end
    end
    nvgClosePath(vg)
    nvgFillPaint(vg, nvgRadialGradient(
        vg,
        -pitchRadius * 0.22,
        -pitchRadius * 0.28,
        pitchRadius * 0.12,
        tipRadius,
        WithAlpha(palette.highlight, alpha),
        WithAlpha(palette.shade, alpha)
    ))
    nvgFill(vg)
    nvgStrokeColor(vg, WithAlpha(palette.edge, alpha))
    nvgStrokeWidth(vg, math.max(1.6, pitchRadius * 0.026))
    nvgStroke(vg)

    -- 工业压铸轮缘：克制的双色倒角配合深色漫画轮廓。
    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, pitchRadius * 0.86)
    nvgStrokeColor(vg, WithAlpha(palette.shade, alpha))
    nvgStrokeWidth(vg, math.max(2.4, pitchRadius * 0.07))
    nvgStroke(vg)
    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, pitchRadius * 0.82)
    nvgStrokeColor(vg, WithAlpha(palette.highlight, alpha * 0.78))
    nvgStrokeWidth(vg, math.max(1.3, pitchRadius * 0.022))
    nvgStroke(vg)

    local apertureRadius = pitchRadius * (
        style == "spiral" and 0.64
        or style == "triad" and 0.62
        or style == "heavy" and 0.53
        or style == "orbit" and 0.65
        or style == "eccentric" and 0.57
        or 0.59
    )
    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, apertureRadius)
    nvgFillColor(vg, nvgRGBA(7, 13, 18, math.floor(245 * alpha)))
    nvgFill(vg)

    local resolvedSpokeCount = spokeCount
        or math.max(4, math.min(8, math.floor(safeTeeth / 8)))
    if style == "triad" then
        resolvedSpokeCount = 3
    elseif style == "spiral" then
        resolvedSpokeCount = 5
    elseif style == "heavy" then
        resolvedSpokeCount = 8
    elseif style == "orbit" then
        resolvedSpokeCount = 7
    elseif style == "eccentric" then
        resolvedSpokeCount = 4
    end
    local hubRadius = pitchRadius * (
        style == "triad" and 0.29
        or style == "heavy" and 0.31
        or style == "eccentric" and 0.22
        or 0.25
    )
    for spoke = 0, resolvedSpokeCount - 1 do
        local spokeAngle = spoke * math.pi * 2 / resolvedSpokeCount
        if style == "eccentric" and spoke % 2 == 1 then
            spokeAngle = spokeAngle + 0.18
        end
        local innerDistance = hubRadius * 0.70
        local outerDistance = apertureRadius * 1.03
        local innerX = math.sin(spokeAngle) * innerDistance
        local innerY = -math.cos(spokeAngle) * innerDistance
        local outerX = math.sin(spokeAngle) * outerDistance
        local outerY = -math.cos(spokeAngle) * outerDistance
        local edgeWidth = style == "heavy"
            and pitchRadius * 0.22
            or style == "triad"
                and pitchRadius * 0.20
                or pitchRadius * 0.15
        local faceWidth = edgeWidth * 0.66

        nvgBeginPath(vg)
        nvgMoveTo(vg, innerX, innerY)
        if style == "spiral" then
            local tangentX = math.cos(spokeAngle) * pitchRadius * 0.25
            local tangentY = math.sin(spokeAngle) * pitchRadius * 0.25
            nvgBezierTo(
                vg,
                innerX + tangentX,
                innerY + tangentY,
                outerX + tangentX * 0.55,
                outerY + tangentY * 0.55,
                outerX,
                outerY
            )
        else
            nvgLineTo(vg, outerX, outerY)
        end
        nvgStrokeColor(vg, WithAlpha(palette.shade, alpha))
        nvgStrokeWidth(vg, math.max(3, edgeWidth))
        nvgStroke(vg)

        nvgBeginPath(vg)
        nvgMoveTo(vg, innerX, innerY)
        if style == "spiral" then
            local tangentX = math.cos(spokeAngle) * pitchRadius * 0.25
            local tangentY = math.sin(spokeAngle) * pitchRadius * 0.25
            nvgBezierTo(
                vg,
                innerX + tangentX,
                innerY + tangentY,
                outerX + tangentX * 0.55,
                outerY + tangentY * 0.55,
                outerX,
                outerY
            )
        else
            nvgLineTo(vg, outerX, outerY)
        end
        nvgStrokeColor(vg, WithAlpha(palette.spoke, alpha))
        nvgStrokeWidth(vg, math.max(2, faceWidth))
        nvgStroke(vg)
    end

    if style == "orbit" then
        for hole = 0, 6 do
            local holeAngle = hole * math.pi * 2 / 7 + 0.18
            local holeX = math.sin(holeAngle) * pitchRadius * 0.42
            local holeY = -math.cos(holeAngle) * pitchRadius * 0.42
            nvgBeginPath(vg)
            nvgCircle(vg, holeX, holeY, pitchRadius * 0.075)
            nvgFillColor(vg, nvgRGBA(5, 10, 14, math.floor(245 * alpha)))
            nvgFill(vg)
            nvgStrokeColor(vg, WithAlpha(palette.highlight, alpha))
            nvgStrokeWidth(vg, math.max(1, pitchRadius * 0.016))
            nvgStroke(vg)
        end
    elseif style == "eccentric" then
        nvgBeginPath(vg)
        nvgCircle(vg, pitchRadius * 0.17, 0, pitchRadius * 0.115)
        nvgFillColor(vg, nvgRGBA(7, 13, 18, math.floor(245 * alpha)))
        nvgFill(vg)
        nvgStrokeColor(vg, WithAlpha(palette.highlight, alpha))
        nvgStrokeWidth(vg, math.max(1.2, pitchRadius * 0.025))
        nvgStroke(vg)
    end

    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, pitchRadius * 0.73)
    nvgStrokeColor(vg, WithAlpha(palette.shade, alpha * 0.78))
    nvgStrokeWidth(vg, math.max(2, pitchRadius * 0.035))
    nvgStroke(vg)
    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, pitchRadius * 0.68)
    nvgStrokeColor(vg, WithAlpha(palette.highlight, alpha * 0.86))
    nvgStrokeWidth(vg, math.max(1.2, pitchRadius * 0.018))
    nvgStroke(vg)

    local rivetCount = math.max(4, math.min(8, resolvedSpokeCount))
    local rivetRadius = math.max(1.8, pitchRadius * 0.045)
    for rivet = 0, rivetCount - 1 do
        local rivetAngle = rivet * math.pi * 2 / rivetCount
            + math.pi / rivetCount
        local rivetX = math.sin(rivetAngle) * pitchRadius * 0.70
        local rivetY = -math.cos(rivetAngle) * pitchRadius * 0.70
        nvgBeginPath(vg)
        nvgCircle(vg, rivetX, rivetY, rivetRadius)
        nvgFillPaint(vg, nvgRadialGradient(
            vg,
            rivetX - rivetRadius * 0.32,
            rivetY - rivetRadius * 0.32,
            rivetRadius * 0.05,
            rivetRadius,
            WithAlpha(palette.highlight, alpha),
            WithAlpha(palette.shade, alpha)
        ))
        nvgFill(vg)
        nvgBeginPath(vg)
        nvgCircle(
            vg,
            rivetX - rivetRadius * 0.22,
            rivetY - rivetRadius * 0.22,
            rivetRadius * 0.18
        )
        nvgFillColor(vg, WithAlpha(palette.highlight, alpha * 0.90))
        nvgFill(vg)
    end

    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, hubRadius)
    nvgFillPaint(vg, nvgRadialGradient(
        vg,
        -hubRadius * 0.25,
        -hubRadius * 0.25,
        hubRadius * 0.08,
        hubRadius,
        WithAlpha(palette.highlight, alpha),
        WithAlpha(palette.shade, alpha)
    ))
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, hubRadius * 0.78)
    nvgStrokeColor(vg, WithAlpha(palette.highlight, alpha * 0.72))
    nvgStrokeWidth(vg, math.max(1.2, pitchRadius * 0.022))
    nvgStroke(vg)

    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, hubRadius * 0.42)
    nvgFillPaint(vg, nvgRadialGradient(
        vg,
        -hubRadius * 0.12,
        -hubRadius * 0.16,
        hubRadius * 0.04,
        hubRadius * 0.42,
        WithAlpha(palette.highlight, alpha),
        WithAlpha(palette.shade, alpha)
    ))
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgCircle(vg, -hubRadius * 0.12, -hubRadius * 0.15, hubRadius * 0.10)
    nvgFillColor(vg, nvgRGBA(255, 248, 180, math.floor(215 * alpha)))
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
    mainAngle,
    externalNodes
)
    local fullTurn = math.pi * 2
    local normalizedMainAngle = mainAngle % fullTurn
    ---@type table<integer, number>
    local visualAngles = { [0] = normalizedMainAngle }

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
                    -- 外啮合相位约束：接触线上父轮的齿相位与
                    -- 子轮的齿槽相位之和恒为半齿距，适用于任意齿数比。
                    visualAngles[index] = GearSystem.ComputeDrivenAngle(
                        parentAngle,
                        contactAngle,
                        parentTeeth,
                        childTeeth
                    )
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

    for nodeId, node in pairs(externalNodes or {}) do
        local parentIndex = node.parentIndex
        local parentAngle = parentIndex ~= nil
                and visualAngles[parentIndex]
            or nil
        local connection = parentAngle ~= nil
                and FindConnection(connections, parentIndex, nodeId)
            or nil
        if connection then
            local parentX, parentY = mainX, mainY
            if type(parentIndex) == "number" and parentIndex > 0 then
                parentX = gears[parentIndex].x
                parentY = gears[parentIndex].y
            end
            local contactAngle = math.atan(
                node.y - parentY,
                node.x - parentX
            )
            local parentTeeth = connection.a == parentIndex
                    and connection.aTeeth
                or connection.bTeeth
            local nodeTeeth = connection.a == nodeId
                    and connection.aTeeth
                or connection.bTeeth
            visualAngles[nodeId] = GearSystem.ComputeDrivenAngle(
                parentAngle,
                contactAngle,
                parentTeeth,
                nodeTeeth
            )
        else
            visualAngles[nodeId] = node.angle or 0
        end
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

function GearRenderer.DrawConnections(
    vg,
    connections,
    gears,
    mainX,
    mainY,
    externalNodes
)
    local function ResolvePosition(nodeId)
        if nodeId == 0 then
            return mainX, mainY
        elseif type(nodeId) == "number" then
            return gears[nodeId].x, gears[nodeId].y
        end
        local node = externalNodes and externalNodes[nodeId]
        return node and node.x or mainX, node and node.y or mainY
    end

    for _, connection in ipairs(connections) do
        local firstX, firstY = ResolvePosition(connection.a)
        local secondX, secondY = ResolvePosition(connection.b)

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

function GearRenderer.DrawMeshContacts(
    vg,
    connections,
    gears,
    mainX,
    mainY,
    externalNodes
)
    local function ResolvePosition(nodeId)
        if nodeId == 0 then
            return mainX, mainY
        elseif type(nodeId) == "number" then
            local gear = gears[nodeId]
            return gear.x, gear.y
        end
        local node = externalNodes and externalNodes[nodeId]
        return node and node.x or mainX, node and node.y or mainY
    end

    for _, connection in ipairs(connections) do
        if connection.aRadius and connection.bRadius then
            local firstX, firstY = ResolvePosition(connection.a)
            local secondX, secondY = ResolvePosition(connection.b)
            local dx = secondX - firstX
            local dy = secondY - firstY
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 0.001 then
                local nx = dx / distance
                local ny = dy / distance
                local contactX = firstX + nx * connection.aRadius
                local contactY = firstY + ny * connection.aRadius
                local toothModule = math.min(
                    connection.aRadius / math.max(1, connection.aTeeth),
                    connection.bRadius / math.max(1, connection.bTeeth)
                )
                local markerRadius = math.max(2.4, toothModule * 1.45)
                local tangentX = -ny
                local tangentY = nx
                local color = connection.conflict
                        and nvgRGBA(255, 69, 57, 255)
                    or connection.powered
                        and nvgRGBA(255, 229, 91, 245)
                    or nvgRGBA(255, 183, 42, 205)

                nvgBeginPath(vg)
                nvgCircle(vg, contactX, contactY, markerRadius * 1.55)
                nvgFillColor(vg, nvgRGBA(10, 13, 14, 205))
                nvgFill(vg)

                nvgBeginPath(vg)
                nvgMoveTo(
                    vg,
                    contactX - nx * markerRadius * 1.20,
                    contactY - ny * markerRadius * 1.20
                )
                nvgLineTo(
                    vg,
                    contactX + tangentX * markerRadius * 0.72,
                    contactY + tangentY * markerRadius * 0.72
                )
                nvgLineTo(
                    vg,
                    contactX + nx * markerRadius * 1.20,
                    contactY + ny * markerRadius * 1.20
                )
                nvgLineTo(
                    vg,
                    contactX - tangentX * markerRadius * 0.72,
                    contactY - tangentY * markerRadius * 0.72
                )
                nvgClosePath(vg)
                nvgFillColor(vg, color)
                nvgFill(vg)
                nvgStrokeColor(vg, nvgRGBA(20, 16, 8, 245))
                nvgStrokeWidth(vg, math.max(1, markerRadius * 0.28))
                nvgStroke(vg)
            end
        end
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
    local cornerRadius = math.min(width, height) * 0.16
    nvgBeginPath(vg)
    nvgRoundedRect(vg, left, top, width, height, cornerRadius)
    nvgFillColor(vg, unlocked
        and nvgRGBA(24, 51, 50, 245)
        or nvgRGBA(37, 43, 48, 225))
    nvgFill(vg)
    nvgStrokeColor(vg, unlocked
        and nvgRGBA(87, 218, 155, 235)
        or nvgRGBA(105, 116, 123, 190))
    nvgStrokeWidth(vg, math.max(1, math.min(width, height) * 0.04))
    nvgStroke(vg)

    local towerWidth = width * 0.15
    local towerGap = width * 0.09
    local towerStartX = left + width * 0.12
    for index = 0, 2 do
        local towerX = towerStartX + index * (towerWidth + towerGap)
        local towerRise = height * (0.32 + index * 0.08)
        nvgBeginPath(vg)
        nvgRect(
            vg,
            towerX,
            top - towerRise,
            towerWidth,
            towerRise + height * 0.22
        )
        nvgFillColor(vg, nvgRGBA(48, 66, 70, 255))
        nvgFill(vg)
        nvgStrokeColor(vg, nvgRGBA(10, 18, 21, 230))
        nvgStrokeWidth(vg, math.max(1, width * 0.025))
        nvgStroke(vg)
    end

    local lampColor = unlocked and running
        and nvgRGBA(71, 247, 153, 255)
        or nvgRGBA(104, 113, 117, 255)
    nvgBeginPath(vg)
    nvgCircle(
        vg,
        left + width * 0.83,
        top + height * 0.22,
        math.max(2, math.min(width, height) * 0.09)
    )
    nvgFillColor(vg, lampColor)
    nvgFill(vg)

    local barLeft = left + width * 0.12
    local barTop = top + height * 0.76
    local barWidth = width * 0.76
    local barHeight = math.max(3, height * 0.12)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, barLeft, barTop, barWidth, barHeight, barHeight * 0.5)
    nvgFillColor(vg, nvgRGBA(9, 20, 22, 235))
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgRoundedRect(
        vg,
        barLeft,
        barTop,
        barWidth * math.max(0, math.min(1, progress)),
        barHeight,
        barHeight * 0.5
    )
    nvgFillColor(vg, lampColor)
    nvgFill(vg)

    local stockGap = width * 0.12
    local stockStartX = x - stockGap * (maxStock - 1) * 0.5
    local stockY = top + height * 0.57
    local stockRadius = math.max(1.5, math.min(width, height) * 0.075)
    for index = 1, maxStock do
        local stockX = stockStartX + (index - 1) * stockGap
        nvgBeginPath(vg)
        nvgCircle(vg, stockX, stockY, stockRadius)
        nvgFillColor(vg, index <= stock
            and nvgRGBA(255, 190, 62, 255)
            or nvgRGBA(72, 82, 84, 220))
        nvgFill(vg)
    end
end

local function DrawMachineLockedBadge(
    vg,
    centerX,
    centerY,
    width,
    requiredTorque,
    requiredLifetimeCoins
)
    local badgeWidth = math.max(82, width * 0.54)
    local badgeHeight = math.max(42, width * 0.25)
    local badgeLeft = centerX - badgeWidth * 0.5
    local badgeTop = centerY - badgeHeight * 0.5

    nvgSave(vg)
    nvgBeginPath(vg)
    nvgRoundedRect(
        vg,
        badgeLeft,
        badgeTop,
        badgeWidth,
        badgeHeight,
        badgeHeight * 0.16
    )
    nvgFillColor(vg, nvgRGBA(4, 6, 8, 228))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(255, 183, 58, 235))
    nvgStrokeWidth(vg, math.max(2, width * 0.012))
    nvgStroke(vg)

    if incomeFont_ >= 0 then
        nvgFontFaceId(vg, incomeFont_)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFontSize(vg, math.max(15, width * 0.105))
        nvgFillColor(vg, nvgRGBA(255, 255, 255, 255))
        nvgText(vg, centerX, centerY - badgeHeight * 0.16, "未解锁")
        nvgFontSize(vg, math.max(11, width * 0.066))
        nvgFillColor(vg, nvgRGBA(255, 202, 88, 255))
        nvgText(
            vg,
            centerX,
            centerY + badgeHeight * 0.22,
            requiredLifetimeCoins
                    and string.format(
                        "资产 %.0f亿 · 扭矩 %g",
                        requiredLifetimeCoins / 100000000,
                        requiredTorque or 0
                    )
                or string.format("需要 %g 扭矩", requiredTorque or 0)
        )
    end
    nvgRestore(vg)
end

function GearRenderer.GetClockHelpCircle(display)
    local width = display.width or 1
    local height = display.height or width
    return display.x + width * 0.42,
        display.y - height * 0.42,
        math.max(11, math.min(width, height) * 0.055)
end

function GearRenderer.GetCurrencyGeneratorHelpCircle(generator)
    local width = generator.imageWidth or generator.bodyWidth or 1
    local height = generator.imageHeight or generator.bodyHeight or width
    return generator.x + width * 0.42,
        generator.y - height * 0.69,
        math.max(11, math.min(width, height) * 0.075)
end

function GearRenderer.GetMiningMachineHelpCircle(machine)
    local width = machine.imageWidth or machine.bodyWidth or 1
    local height = machine.imageHeight or machine.bodyHeight or width
    return machine.x + width * 0.43,
        machine.y - height * 0.72,
        math.max(13, math.min(width, height) * 0.036)
end

function GearRenderer.DrawMachineHelpIcon(vg, x, y, radius)
    DrawStatusGlow(
        vg,
        x,
        y,
        radius * 1.45,
        nvgRGBA(255, 177, 48, 80)
    )
    nvgBeginPath(vg)
    nvgCircle(vg, x, y, radius)
    nvgFillColor(vg, nvgRGBA(11, 16, 20, 245))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(255, 190, 65, 255))
    nvgStrokeWidth(vg, math.max(2.5, radius * 0.16))
    nvgStroke(vg)

    if incomeFont_ >= 0 then
        nvgFontFaceId(vg, incomeFont_)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFontSize(vg, radius * 1.42)
        nvgFillColor(vg, nvgRGBA(255, 255, 255, 255))
        nvgText(vg, x, y + radius * 0.04, "?")
    end
end

function GearRenderer.DrawCurrencyGenerator(
    vg,
    generator,
    progress,
    warningPhase,
    visualAngle,
    locked
)
    local running = generator.powered == true
    local pulse = 0.5 + 0.5 * math.sin((warningPhase or 0) * 5)
    local bodyLeft = generator.bodyX - generator.bodyWidth * 0.5
    local bodyTop = generator.bodyY - generator.bodyHeight * 0.5
    local statusColor = running
        and nvgRGBA(90, 232, 137, 255)
        or generator.status == "jammed"
            and nvgRGBA(255, 72, 63, 255)
            or generator.status == "overloaded"
                and nvgRGBA(255, 98, 54, 255)
                or generator.status == "insufficientTorque"
                    and nvgRGBA(255, 50, 46, 255)
                    or nvgRGBA(224, 161, 62, 255)

    if running then
        DrawStatusGlow(
            vg,
            generator.bodyX,
            generator.bodyY,
            generator.bodyWidth * 0.42,
            nvgRGBA(255, 188, 66, math.floor(55 + pulse * 45))
        )
    elseif generator.status == "jammed"
        or generator.status == "overloaded"
        or generator.status == "insufficientTorque" then
        DrawStatusGlow(
            vg,
            generator.bodyX,
            generator.bodyY,
            generator.bodyWidth * (0.45 + pulse * 0.035),
            nvgRGBA(255, 45, 42, math.floor(70 + pulse * 55))
        )
    end
    if (generator.rewardFlash or 0) > 0 then
        DrawStatusGlow(
            vg,
            generator.bodyX,
            generator.bodyY,
            generator.bodyWidth * (0.62 + generator.rewardFlash * 0.12),
            nvgRGBA(
                255,
                224,
                101,
                math.floor(180 * generator.rewardFlash)
            )
        )
    end

    local bodyImage = currencyGeneratorBodyImage_
    local hasAnimatedBody = running
        and #currencyGeneratorAnimationImages_ > 0
    if hasAnimatedBody then
        local animationFrame = math.floor(
            (generator.animationTime or 0)
                * CURRENCY_GENERATOR_ANIMATION_FPS
        ) % CURRENCY_GENERATOR_FRAME_COUNT + 1
        bodyImage = currencyGeneratorAnimationImages_[animationFrame]
    end

    if bodyImage and bodyImage > 0 then
        local imageWidth = generator.imageWidth or generator.bodyWidth
        local imageHeight = generator.imageHeight or generator.bodyHeight
        local imageLeft = generator.x - imageWidth * 0.5
        local imageTop = generator.y - imageHeight * 0.79
        nvgBeginPath(vg)
        nvgRect(
            vg,
            imageLeft,
            imageTop,
            imageWidth,
            imageHeight
        )
        nvgFillPaint(vg, nvgImagePattern(
            vg,
            imageLeft,
            imageTop,
            imageWidth,
            imageHeight,
            0,
            bodyImage,
            generator.status == "unmeshed" and 0.82 or 1
        ))
        nvgFill(vg)
    else
        nvgBeginPath(vg)
        nvgRoundedRect(
            vg,
            bodyLeft,
            bodyTop,
            generator.bodyWidth,
            generator.bodyHeight,
            generator.bodyWidth * 0.15
        )
        nvgFillPaint(vg, nvgLinearGradient(
            vg,
            bodyLeft,
            bodyTop,
            bodyLeft + generator.bodyWidth,
            bodyTop + generator.bodyHeight,
            nvgRGBA(104, 67, 31, 255),
            nvgRGBA(42, 27, 20, 255)
        ))
        nvgFill(vg)

    nvgBeginPath(vg)
    nvgRoundedRect(
        vg,
        bodyLeft,
        bodyTop,
        generator.bodyWidth,
        generator.bodyHeight,
        generator.bodyWidth * 0.15
    )
    nvgStrokeColor(vg, nvgRGBA(219, 161, 73, 255))
    nvgStrokeWidth(vg, 3)
    nvgStroke(vg)

    local clockRadius = generator.bodyWidth * 0.34
    local clockX = generator.bodyX
    local clockY = generator.bodyY - generator.bodyHeight * 0.13
    nvgBeginPath(vg)
    nvgCircle(vg, clockX, clockY, clockRadius)
    nvgFillColor(vg, nvgRGBA(222, 201, 155, 255))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(55, 36, 24, 255))
    nvgStrokeWidth(vg, 4)
    nvgStroke(vg)

    for marker = 0, 11 do
        local markerAngle = marker * math.pi / 6
        local inner = clockRadius * 0.78
        local outer = clockRadius * 0.91
        nvgBeginPath(vg)
        nvgMoveTo(
            vg,
            clockX + math.sin(markerAngle) * inner,
            clockY - math.cos(markerAngle) * inner
        )
        nvgLineTo(
            vg,
            clockX + math.sin(markerAngle) * outer,
            clockY - math.cos(markerAngle) * outer
        )
        nvgStrokeColor(vg, nvgRGBA(68, 44, 25, 255))
        nvgStrokeWidth(vg, marker % 3 == 0 and 3 or 1.5)
        nvgStroke(vg)
    end

    local handAngle = (progress or 0) * math.pi * 2
    nvgBeginPath(vg)
    nvgMoveTo(vg, clockX, clockY)
    nvgLineTo(
        vg,
        clockX + math.sin(handAngle) * clockRadius * 0.68,
        clockY - math.cos(handAngle) * clockRadius * 0.68
    )
    nvgStrokeColor(vg, nvgRGBA(104, 39, 28, 255))
    nvgStrokeWidth(vg, 3)
    nvgStroke(vg)
    nvgBeginPath(vg)
    nvgCircle(vg, clockX, clockY, 5)
    nvgFillColor(vg, nvgRGBA(103, 57, 27, 255))
    nvgFill(vg)

    local barLeft = bodyLeft + generator.bodyWidth * 0.16
    local barTop = bodyTop + generator.bodyHeight * 0.81
    local barWidth = generator.bodyWidth * 0.68
    nvgBeginPath(vg)
    nvgRoundedRect(vg, barLeft, barTop, barWidth, 9, 4)
    nvgFillColor(vg, nvgRGBA(24, 16, 14, 240))
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgRoundedRect(
        vg,
        barLeft,
        barTop,
        barWidth * math.max(0, math.min(1, progress or 0)),
        9,
        4
    )
    nvgFillColor(vg, statusColor)
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgCircle(
        vg,
        bodyLeft + generator.bodyWidth * 0.84,
        bodyTop + generator.bodyHeight * 0.12,
        6
    )
    nvgFillColor(vg, statusColor)
    nvgFill(vg)
    end

    if locked then
        local overlayWidth = generator.imageWidth or generator.bodyWidth
        local overlayHeight = generator.imageHeight or generator.bodyHeight
        local overlayLeft = generator.x - overlayWidth * 0.5
        local overlayTop = generator.y - overlayHeight * 0.79
        if bodyImage and bodyImage > 0 then
            nvgBeginPath(vg)
            nvgRect(
                vg,
                overlayLeft,
                overlayTop,
                overlayWidth,
                overlayHeight
            )
            nvgFillPaint(vg, nvgImagePatternTinted(
                vg,
                overlayLeft,
                overlayTop,
                overlayWidth,
                overlayHeight,
                0,
                bodyImage,
                nvgRGBA(7, 8, 10, 252)
            ))
            nvgFill(vg)
        else
            nvgBeginPath(vg)
            nvgRoundedRect(
                vg,
                bodyLeft,
                bodyTop,
                generator.bodyWidth,
                generator.bodyHeight,
                generator.bodyWidth * 0.15
            )
            nvgFillColor(vg, nvgRGBA(3, 5, 7, 240))
            nvgFill(vg)
        end
        DrawMachineLockedBadge(
            vg,
            generator.bodyX,
            generator.bodyY,
            generator.bodyWidth,
            GearDefinitions.CurrencyGenerator.requiredTorque
        )
    end

    nvgSave(vg)
    if locked then
        local visibleRadius = generator.radius * 1.35
        nvgScissor(
            vg,
            generator.x - visibleRadius,
            generator.y,
            visibleRadius * 2,
            visibleRadius
        )
    end
    nvgTranslate(vg, generator.x, generator.y)
    nvgRotate(vg, visualAngle or generator.angle or 0)
    local rings = GearDefinitions.CurrencyGenerator.rings
    DrawProceduralGear(
        vg,
        generator.radius,
        rings.outer.teeth,
        GEAR_PALETTES.compoundInner,
        generator.status == "unmeshed" and 0.82 or 1,
        4,
        "orbit"
    )
    nvgRestore(vg)
end

function GearRenderer.DrawPowerCable(
    vg,
    generatorDisplay,
    miningMachine,
    energized,
    phase
)
    local direction = (miningMachine.x or 0) >= generatorDisplay.x
            and 1
        or -1
    local startX = generatorDisplay.x
        + direction * (generatorDisplay.width or 1) * 0.42
    local startY = generatorDisplay.y
        + (generatorDisplay.height or 1) * 0.22
    local endX = (miningMachine.bodyX or miningMachine.x)
        - direction * (miningMachine.bodyWidth or 1) * 0.46
    local endY = (miningMachine.bodyY or miningMachine.y)
        + (miningMachine.bodyHeight or 1) * 0.26
    local controlOffset = math.max(
        40,
        math.abs(endX - startX) * 0.28
    )
    local control1X = startX + direction * controlOffset
    local control1Y = startY + 32
    local control2X = endX - direction * controlOffset
    local control2Y = endY + 32

    local function StrokeCable(color, width)
        nvgBeginPath(vg)
        nvgMoveTo(vg, startX, startY)
        nvgBezierTo(
            vg,
            control1X,
            control1Y,
            control2X,
            control2Y,
            endX,
            endY
        )
        nvgStrokeColor(vg, color)
        nvgStrokeWidth(vg, width)
        nvgStroke(vg)
    end

    StrokeCable(nvgRGBA(3, 8, 13, 245), 15)
    StrokeCable(nvgRGBA(28, 46, 58, 255), 10)
    StrokeCable(nvgRGBA(186, 116, 36, 215), 3)

    local socketRadius = 8
    for _, socket in ipairs({
        { x = startX, y = startY },
        { x = endX, y = endY },
    }) do
        nvgBeginPath(vg)
        nvgCircle(vg, socket.x, socket.y, socketRadius)
        nvgFillColor(vg, nvgRGBA(22, 35, 43, 255))
        nvgFill(vg)
        nvgStrokeColor(vg, nvgRGBA(224, 151, 52, 255))
        nvgStrokeWidth(vg, 3)
        nvgStroke(vg)
    end

    if not energized then
        return
    end

    StrokeCable(nvgRGBA(37, 213, 255, 70), 11)
    StrokeCable(nvgRGBA(150, 244, 255, 205), 2.2)
    local resolvedPhase = phase or 0
    for sparkIndex = 0, 9 do
        local t = (resolvedPhase * 0.42 + sparkIndex / 10) % 1
        local inverse = 1 - t
        local sparkX = inverse * inverse * inverse * startX
            + 3 * inverse * inverse * t * control1X
            + 3 * inverse * t * t * control2X
            + t * t * t * endX
        local sparkY = inverse * inverse * inverse * startY
            + 3 * inverse * inverse * t * control1Y
            + 3 * inverse * t * t * control2Y
            + t * t * t * endY
        local sparkRadius = 3.2 + math.sin(
            resolvedPhase * 8 + sparkIndex
        ) * 0.8
        DrawStatusGlow(
            vg,
            sparkX,
            sparkY,
            sparkRadius * 3.2,
            nvgRGBA(50, 221, 255, 125)
        )
        nvgBeginPath(vg)
        nvgCircle(vg, sparkX, sparkY, sparkRadius)
        nvgFillColor(vg, nvgRGBA(205, 251, 255, 255))
        nvgFill(vg)
    end
end

function GearRenderer.DrawMiningMachine(
    vg,
    machine,
    progress,
    ore,
    maxOre,
    warningPhase,
    locked
)
    local running = machine.miningEfficiency ~= nil
        and machine.miningEfficiency > 0
    local pulse = 0.5 + 0.5 * math.sin((warningPhase or 0) * 4.2)
    local imageWidth = machine.imageWidth or machine.bodyWidth or 1
    local imageHeight = machine.imageHeight or machine.bodyHeight or imageWidth
    local imageLeft = machine.x - imageWidth * 0.5
    local imageTop = machine.y - imageHeight * 0.82
    local alpha = machine.status == "unmeshed" and 0.82 or 1
    local statusColor = running
        and nvgRGBA(57, 226, 199, 255)
        or machine.status == "jammed"
            and nvgRGBA(255, 72, 63, 255)
            or machine.status == "overloaded"
                and nvgRGBA(255, 98, 54, 255)
                or machine.status == "insufficientTorque"
                    and nvgRGBA(255, 177, 61, 255)
                    or nvgRGBA(100, 129, 145, 235)

    if running then
        DrawStatusGlow(
            vg,
            machine.bodyX or machine.x,
            machine.bodyY or machine.y,
            imageWidth * (0.38 + pulse * 0.03),
            nvgRGBA(44, 221, 203, math.floor(42 + pulse * 35))
        )
    end
    if (machine.rewardFlash or 0) > 0 then
        DrawStatusGlow(
            vg,
            machine.bodyX or machine.x,
            machine.bodyY or machine.y,
            imageWidth * (0.48 + machine.rewardFlash * 0.10),
            nvgRGBA(
                64,
                235,
                255,
                math.floor(175 * machine.rewardFlash)
            )
        )
    end

    local machineImage = miningMachineImage_
    if running and #miningMachineAnimationImages_ > 0 then
        local animationFrame = math.floor(
            (machine.animationTime or 0)
                * MINING_MACHINE_ANIMATION_FPS
        ) % MINING_MACHINE_FRAME_COUNT + 1
        machineImage = miningMachineAnimationImages_[animationFrame]
    end
    if machineImage and machineImage > 0 then
        nvgBeginPath(vg)
        nvgRect(vg, imageLeft, imageTop, imageWidth, imageHeight)
        nvgFillPaint(vg, nvgImagePattern(
            vg,
            imageLeft,
            imageTop,
            imageWidth,
            imageHeight,
            0,
            machineImage,
            alpha
        ))
        nvgFill(vg)
    end

    local oreRatio = math.max(0, math.min(1, (ore or 0) / math.max(1, maxOre or 1)))
    local stockLeft = imageLeft + imageWidth * 0.30
    local stockTop = imageTop + imageHeight * 0.12
    local stockWidth = imageWidth * 0.40
    local stockHeight = math.max(4, imageHeight * 0.025)
    nvgBeginPath(vg)
    nvgRoundedRect(
        vg,
        stockLeft,
        stockTop,
        stockWidth,
        stockHeight,
        stockHeight * 0.5
    )
    nvgFillColor(vg, nvgRGBA(8, 22, 31, 225))
    nvgFill(vg)
    if oreRatio > 0 then
        nvgBeginPath(vg)
        nvgRoundedRect(
            vg,
            stockLeft,
            stockTop,
            stockWidth * oreRatio,
            stockHeight,
            stockHeight * 0.5
        )
        nvgFillPaint(vg, nvgLinearGradient(
            vg,
            stockLeft,
            stockTop,
            stockLeft + stockWidth,
            stockTop,
            nvgRGBA(37, 222, 245, 255),
            nvgRGBA(255, 187, 54, 255)
        ))
        nvgFill(vg)
    end

    local progressLeft = imageLeft + imageWidth * 0.29
    local progressTop = imageTop + imageHeight * 0.715
    local progressWidth = imageWidth * 0.42
    local progressHeight = math.max(4, imageHeight * 0.022)
    nvgBeginPath(vg)
    nvgRoundedRect(
        vg,
        progressLeft,
        progressTop,
        progressWidth,
        progressHeight,
        progressHeight * 0.5
    )
    nvgFillColor(vg, nvgRGBA(7, 17, 24, 230))
    nvgFill(vg)
    if (progress or 0) > 0 then
        nvgBeginPath(vg)
        nvgRoundedRect(
            vg,
            progressLeft,
            progressTop,
            progressWidth * math.max(0, math.min(1, progress or 0)),
            progressHeight,
            progressHeight * 0.5
        )
        nvgFillColor(vg, statusColor)
        nvgFill(vg)
    end

    nvgBeginPath(vg)
    nvgCircle(
        vg,
        imageLeft + imageWidth * 0.77,
        imageTop + imageHeight * 0.63,
        math.max(3, imageWidth * 0.018)
    )
    nvgFillColor(vg, statusColor)
    nvgFill(vg)

    if locked then
        if machineImage and machineImage > 0 then
            nvgBeginPath(vg)
            nvgRect(vg, imageLeft, imageTop, imageWidth, imageHeight)
            nvgFillPaint(vg, nvgImagePatternTinted(
                vg,
                imageLeft,
                imageTop,
                imageWidth,
                imageHeight,
                0,
                machineImage,
                nvgRGBA(6, 8, 10, 252)
            ))
            nvgFill(vg)
        else
            nvgBeginPath(vg)
            nvgRoundedRect(
                vg,
                imageLeft,
                imageTop,
                imageWidth,
                imageHeight,
                imageWidth * 0.05
            )
            nvgFillColor(vg, nvgRGBA(3, 5, 7, 240))
            nvgFill(vg)
        end
        DrawMachineLockedBadge(
            vg,
            machine.bodyX or machine.x,
            machine.bodyY or machine.y,
            imageWidth * 0.5,
            GearDefinitions.MiningMachine.requiredTorque,
            GearDefinitions.MiningMachine.requiredLifetimeCoins
        )
    end
end

function GearRenderer.DrawClockAnimation(vg, display, locked)
    if display.visible == false then
        return
    end

    local width = display.width or 1
    local height = display.height or width
    local left = display.x - width * 0.5
    local top = display.y - height * 0.5
    local running = display.running ~= false
    local imageHandle = clockIdleImage_
    if running and #clockAnimationImages_ > 0 then
        local animationFrame = math.floor(
            (display.animationTime or 0) * CLOCK_RUNNING_ANIMATION_FPS
        ) % CLOCK_RUNNING_FRAME_COUNT + 1
        imageHandle = clockAnimationImages_[animationFrame]
    end
    if not imageHandle or imageHandle <= 0 then
        return
    end

    nvgBeginPath(vg)
    nvgRect(vg, left, top, width, height)
    nvgFillPaint(vg, nvgImagePattern(
        vg,
        left,
        top,
        width,
        height,
        0,
        imageHandle,
        display.alpha or 1
    ))
    nvgFill(vg)

    if locked then
        nvgBeginPath(vg)
        nvgRect(vg, left, top, width, height)
        nvgFillPaint(vg, nvgImagePatternTinted(
            vg,
            left,
            top,
            width,
            height,
            0,
            imageHandle,
            nvgRGBA(6, 8, 10, 252)
        ))
        nvgFill(vg)
    end

    if powerGeneratorGearImage_ and powerGeneratorGearImage_ > 0 then
        local gearSize = display.gearSize or width * 0.28
        local gearX = display.interfaceX or (display.x - width * 0.38)
        local gearY = display.interfaceY or display.y
        local gearAlpha = display.alpha or 1
        nvgSave(vg)
        if locked then
            nvgScissor(
                vg,
                gearX - gearSize * 0.6,
                gearY,
                gearSize * 1.2,
                gearSize * 0.6
            )
        end
        nvgTranslate(vg, gearX, gearY)
        nvgRotate(vg, display.gearAngle or 0)
        local gearLeft = -gearSize * 0.5
        local gearTop = -gearSize * 0.5
        nvgBeginPath(vg)
        nvgRect(vg, gearLeft, gearTop, gearSize, gearSize)
        nvgFillPaint(vg, nvgImagePattern(
            vg,
            gearLeft,
            gearTop,
            gearSize,
            gearSize,
            0,
            powerGeneratorGearImage_,
            gearAlpha
        ))
        nvgFill(vg)
        nvgRestore(vg)
    end

    if locked then
        DrawMachineLockedBadge(
            vg,
            display.x,
            display.y,
            width * 0.72,
            GearDefinitions.ClockInterface.requiredTorque,
            GearDefinitions.ClockInterface.requiredLifetimeCoins
        )
    end
end

function GearRenderer.DrawPowerGeneratorAnimation(vg, display, locked)
    if display.visible == false then
        return
    end

    local width = display.width or 1
    local height = display.height or width * 0.75
    local alpha = display.alpha or 1
    local left = display.x - width * 0.5
    local top = display.y - height * 0.5
    local running = display.mechanicallyRotating == true
        or display.powered == true

    local imageHandle = powerGeneratorIdleImage_
    if running and #powerGeneratorAnimationImages_ > 0 then
        local animationFrame = math.floor(
            (display.animationTime or 0) * POWER_GENERATOR_ANIMATION_FPS
        ) % POWER_GENERATOR_FRAME_COUNT + 1
        imageHandle = powerGeneratorAnimationImages_[animationFrame]
    end
    if not imageHandle or imageHandle <= 0 then
        return
    end

    nvgBeginPath(vg)
    nvgRect(vg, left, top, width, height)
    nvgFillPaint(vg, nvgImagePattern(
        vg,
        left,
        top,
        width,
        height,
        0,
        imageHandle,
        alpha
    ))
    nvgFill(vg)

    if locked then
        nvgBeginPath(vg)
        nvgRect(vg, left, top, width, height)
        nvgFillPaint(vg, nvgImagePatternTinted(
            vg,
            left,
            top,
            width,
            height,
            0,
            imageHandle,
            nvgRGBA(6, 8, 10, 252)
        ))
        nvgFill(vg)
    end

    if powerGeneratorGearImage_ and powerGeneratorGearImage_ > 0 then
        local gearSize = display.gearSize or width * 0.3
        local gearX = display.interfaceX or display.x
        local gearY = display.interfaceY
            or (display.y + height * 0.15)
        nvgSave(vg)
        if locked then
            nvgScissor(
                vg,
                gearX - gearSize * 0.6,
                gearY,
                gearSize * 1.2,
                gearSize * 0.6
            )
        end
        nvgTranslate(vg, gearX, gearY)
        nvgRotate(
            vg,
            display.gearAngle
                or (display.animationTime or 0) * math.pi * 0.9
        )
        local gearLeft = -gearSize * 0.5
        local gearTop = -gearSize * 0.5
        nvgBeginPath(vg)
        nvgRect(vg, gearLeft, gearTop, gearSize, gearSize)
        nvgFillPaint(vg, nvgImagePattern(
            vg,
            gearLeft,
            gearTop,
            gearSize,
            gearSize,
            0,
            powerGeneratorGearImage_,
            alpha
        ))
        nvgFill(vg)
        nvgRestore(vg)
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
    local pulseAlpha = math.max(0, math.min(1, pulse or 0))
    if isPowered then
        DrawStatusGlow(
            vg,
            x,
            y,
            radius,
            nvgRGBA(194, 142, 45, math.floor(52 + pulseAlpha * 28))
        )
    end

    GearRenderer.DrawShopGearIcon(
        vg,
        "main",
        x,
        y,
        GearDefinitions.GetTipRadius(
            radius,
            GearDefinitions.Main.rings.outer.teeth
        ) * 2,
        isPowered and 1 or 0.82,
        angle,
        radius
    )

    if isSpeedCapped then
        local flash = 0.5 + 0.5 * math.sin((warningPhase or 0) * 9)
        nvgBeginPath(vg)
        nvgCircle(vg, x, y, radius * 1.12)
        nvgStrokeColor(vg, nvgRGBA(255, 43, 43, math.floor(125 + flash * 130)))
        nvgStrokeWidth(vg, 4 + flash * 3)
        nvgStroke(vg)
    end
end

function GearRenderer.DrawOilEffect(vg, x, y, radius, phase, strength)
    local alpha = math.max(0, math.min(1, strength or 1))
    if alpha <= 0 then
        return
    end

    local flow = (phase or 0) * 0.34
    local fullTurn = math.pi * 2
    local filmRadius = radius * 0.97

    -- 一整层透明油水膜贴在齿轮盘面，边缘缓慢起伏。
    nvgBeginPath(vg)
    for step = 0, 48 do
        local angle = fullTurn * step / 48
        local ripple = (
            math.sin(angle * 3.0 + flow * 1.3) * 0.020
            + math.sin(angle * 7.0 - flow * 0.8) * 0.012
        ) * radius
        local edgeRadius = filmRadius + ripple
        local px = x + math.cos(angle) * edgeRadius
        local py = y + math.sin(angle) * edgeRadius
        if step == 0 then
            nvgMoveTo(vg, px, py)
        else
            nvgLineTo(vg, px, py)
        end
    end
    nvgClosePath(vg)
    nvgFillPaint(vg, nvgRadialGradient(
        vg,
        x - radius * 0.24,
        y - radius * 0.28,
        radius * 0.08,
        filmRadius,
        nvgRGBA(255, 239, 173, math.floor(46 * alpha)),
        nvgRGBA(78, 105, 66, math.floor(88 * alpha))
    ))
    nvgFill(vg)

    -- 叠加宽而柔和的油膜色块，形成油水交界和薄膜色散。
    local filmColors = {
        { 69, 232, 211 },
        { 146, 105, 238 },
        { 255, 191, 74 },
    }
    for layer = 1, 3 do
        local color = filmColors[layer]
        local baseAngle = flow * (0.16 + layer * 0.025)
            + fullTurn * (layer - 1) / 3
        local span = 1.68 + layer * 0.16
        nvgBeginPath(vg)
        for step = 0, 18 do
            local t = step / 18
            local angle = baseAngle + (t - 0.5) * span
            local wave = math.sin(t * math.pi * 2 + flow + layer) * radius * 0.025
            local bandRadius = radius * (0.68 + layer * 0.055) + wave
            local px = x + math.cos(angle) * bandRadius
            local py = y + math.sin(angle) * bandRadius
            if step == 0 then
                nvgMoveTo(vg, px, py)
            else
                nvgLineTo(vg, px, py)
            end
        end
        nvgStrokeColor(vg, nvgRGBA(
            color[1],
            color[2],
            color[3],
            math.floor(30 * alpha)
        ))
        nvgStrokeWidth(vg, math.max(7, radius * 0.16))
        nvgStroke(vg)

        nvgBeginPath(vg)
        for step = 0, 18 do
            local t = step / 18
            local angle = baseAngle + (t - 0.5) * span
            local wave = math.sin(t * math.pi * 2 + flow + layer) * radius * 0.025
            local bandRadius = radius * (0.68 + layer * 0.055) + wave
            local px = x + math.cos(angle) * bandRadius
            local py = y + math.sin(angle) * bandRadius
            if step == 0 then
                nvgMoveTo(vg, px, py)
            else
                nvgLineTo(vg, px, py)
            end
        end
        nvgStrokeColor(vg, nvgRGBA(
            math.min(255, color[1] + 50),
            math.min(255, color[2] + 35),
            math.min(255, color[3] + 30),
            math.floor(72 * alpha)
        ))
        nvgStrokeWidth(vg, math.max(1.2, radius * 0.022))
        nvgStroke(vg)
    end

    -- 宽波纹从齿面外侧缓慢收向轴心，不形成硬质油路。
    for waveIndex = 1, 3 do
        local inward = (flow * 0.15 + (waveIndex - 1) / 3) % 1
        local waveRadius = radius * (0.88 - inward * 0.57)
        local waveAlpha = math.sin(inward * math.pi)
        nvgBeginPath(vg)
        for step = 0, 40 do
            local angle = fullTurn * step / 40
            local distortion = (
                math.sin(angle * 4 - flow * 1.4 + waveIndex) * 0.024
                + math.sin(angle * 9 + flow * 0.7) * 0.010
            ) * radius
            local px = x + math.cos(angle) * (waveRadius + distortion)
            local py = y + math.sin(angle) * (waveRadius + distortion)
            if step == 0 then
                nvgMoveTo(vg, px, py)
            else
                nvgLineTo(vg, px, py)
            end
        end
        nvgClosePath(vg)
        nvgStrokeColor(vg, nvgRGBA(
            224,
            249,
            218,
            math.floor((22 + waveAlpha * 42) * alpha)
        ))
        nvgStrokeWidth(vg, math.max(3, radius * 0.075))
        nvgStroke(vg)
        nvgStrokeColor(vg, nvgRGBA(
            255,
            240,
            172,
            math.floor((34 + waveAlpha * 54) * alpha)
        ))
        nvgStrokeWidth(vg, math.max(1, radius * 0.014))
        nvgStroke(vg)
    end

    -- 湿润表面的斜向反光随油膜轻微漂移。
    local sheenOffset = math.sin(flow * 1.7) * radius * 0.08
    nvgBeginPath(vg)
    nvgEllipse(
        vg,
        x - radius * 0.20 + sheenOffset,
        y - radius * 0.25,
        radius * 0.42,
        radius * 0.13
    )
    nvgFillPaint(vg, nvgLinearGradient(
        vg,
        x - radius * 0.58,
        y - radius * 0.40,
        x + radius * 0.22,
        y - radius * 0.10,
        nvgRGBA(255, 255, 235, math.floor(82 * alpha)),
        nvgRGBA(83, 221, 215, 0)
    ))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgCircle(vg, x, y, radius * 0.22)
    nvgStrokeColor(vg, nvgRGBA(126, 246, 218, math.floor(72 * alpha)))
    nvgStrokeWidth(vg, math.max(1.2, radius * 0.024))
    nvgStroke(vg)
end

function GearRenderer.DrawRevenueGear(
    vg,
    gear,
    isDragging,
    isSelected,
    visualAngle,
    placementValid,
    effectPhase
)
    local radius = gear.radius
    local visualRadius = GearDefinitions.GetTipRadius(
        radius,
        gear.teeth
    )
    if gear.connected then
        DrawStatusGlow(vg, gear.x, gear.y, radius, nvgRGBA(62, 232, 143, 90))
    end
    if gear.lubricationSource then
        DrawStatusGlow(vg, gear.x, gear.y, radius * 1.08, nvgRGBA(49, 255, 205, 145))
    end

    local renderedAngle = visualAngle or gear.angle
    local alpha = gear.jammed and 0.68 or 1
    local drawX = gear.x
    local drawY = gear.y
    if gear.localJammed then
        local jamCycle = ((effectPhase or 0) * 2.4
            + (gear.id or 0) * 0.17) % 1
        local jamTravel = math.pi * 2
            / math.max(6, gear.teeth or 16)
            * 0.42
        local jamOffset = 0
        if jamCycle < 0.50 then
            local approach = jamCycle / 0.50
            jamOffset = 1 - (1 - approach) * (1 - approach)
        elseif jamCycle < 0.68 then
            local recoil = (jamCycle - 0.50) / 0.18
            jamOffset = 1 - recoil * 1.18
        elseif jamCycle < 0.80 then
            local settle = (jamCycle - 0.68) / 0.12
            jamOffset = -0.18 * (1 - settle)
        end
        local attemptedDirection = gear.spinDirection ~= 0
                and gear.spinDirection
            or ((gear.id or 0) % 2 == 0 and 1 or -1)
        renderedAngle = renderedAngle
            + jamOffset * jamTravel * attemptedDirection
    end
    GearRenderer.DrawShopGearIcon(
        vg,
        gear.gearType,
        drawX,
        drawY,
        visualRadius * 2,
        alpha,
        renderedAngle,
        radius
    )
    if gear.gearType ~= "lubricant"
        and (gear.oilEffectRemaining or 0) > 0 then
        local effectDuration = GearDefinitions.Get("lubricant").oilEffectDuration
        GearRenderer.DrawOilEffect(
            vg,
            drawX,
            drawY,
            visualRadius,
            effectPhase or 0,
            math.min(1, (gear.oilEffectRemaining or 0) / effectDuration * 2)
        )
    end

    nvgSave(vg)
    nvgTranslate(vg, drawX, drawY)
    nvgRotate(vg, renderedAngle)
    if gear.maintenanceJammed then
        DrawSelectionRing(vg, visualRadius, nvgRGBA(255, 132, 48, 255), 4)
        nvgRotate(vg, -renderedAngle)
        nvgBeginPath(vg)
        nvgCircle(vg, 0, -radius * 0.28, math.max(3.5, radius * 0.08))
        nvgFillColor(vg, nvgRGBA(255, 174, 54, 255))
        nvgFill(vg)
    elseif gear.jammed then
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

function GearRenderer.DrawShopGearIcon(
    vg,
    gearType,
    x,
    y,
    boxSize,
    alpha,
    angle,
    pitchRadius
)
    local definition = gearType == "main"
        and GearDefinitions.Main
        or GearDefinitions.Get(gearType)
    local outerTeeth = GearDefinitions.GetRings(gearType).outer.teeth
    local visibleTipRadius
    if pitchRadius then
        visibleTipRadius = GearDefinitions.GetTipRadius(
            pitchRadius,
            outerTeeth
        )
    else
        visibleTipRadius = boxSize * 0.46
    end

    local rings = GearDefinitions.GetRings(gearType)
    if gearType == "large_compound" then
        local outerImageSize = visibleTipRadius * 2
            / GEAR_IMAGE_RADIUS_FACTORS.large
        local outerPitchRadius = pitchRadius
            or visibleTipRadius
                / (
                    1
                    + GearDefinitions.GearProfile.addendum * 2
                        / math.max(1, rings.outer.teeth)
                )
        local innerPitchRadius = outerPitchRadius * rings.inner.radiusScale
        local innerTipRadius = GearDefinitions.GetTipRadius(
            innerPitchRadius,
            rings.inner.teeth
        )
        local innerImageSize = innerTipRadius * 2
            / GEAR_IMAGE_RADIUS_FACTORS.small
        local drewOuter = DrawGearImage(
            vg,
            "large",
            x,
            y,
            outerImageSize,
            alpha,
            angle or 0
        )
        local drewInner = DrawGearImage(
            vg,
            "small",
            x,
            y,
            innerImageSize,
            alpha,
            angle or 0
        )
        if drewOuter and drewInner then
            return
        end
    end

    local radiusFactor = GEAR_IMAGE_RADIUS_FACTORS[gearType]
        or GEAR_IMAGE_RADIUS_FACTORS.small
    local imageSize = visibleTipRadius * 2 / radiusFactor
    if DrawGearImage(
        vg,
        gearType,
        x,
        y,
        imageSize,
        alpha,
        angle or 0
    ) then
        return
    end

    local outerTipScale = 1
        + GearDefinitions.GearProfile.addendum * 2
            / math.max(1, rings.outer.teeth)
    local radius = math.max(1, boxSize * 0.46 / outerTipScale)

    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, angle or 0)

    if gearType == "main" then
        DrawProceduralGear(
            vg,
            radius,
            rings.outer.teeth,
            GEAR_PALETTES.main,
            alpha or 1,
            8,
            "heavy"
        )
        DrawProceduralGear(
            vg,
            radius * rings.inner.radiusScale,
            rings.inner.teeth,
            GEAR_PALETTES.mainInner,
            alpha or 1,
            4,
            "triad"
        )
    elseif gearType == "large_compound" then
        DrawProceduralGear(
            vg,
            radius,
            rings.outer.teeth,
            GEAR_PALETTES.large,
            alpha or 1,
            8,
            "heavy"
        )
        DrawProceduralGear(
            vg,
            radius * rings.inner.radiusScale,
            rings.inner.teeth,
            GEAR_PALETTES.small,
            alpha or 1,
            4,
            "triad"
        )
    elseif gearType == "compound" or gearType == "momma" then
        local outerPalette = gearType == "compound"
            and GEAR_PALETTES.compoundOuter
            or GEAR_PALETTES.momma
        local innerPalette = gearType == "compound"
            and GEAR_PALETTES.compoundInner
            or GEAR_PALETTES.mommaInner
        DrawProceduralGear(
            vg,
            radius,
            rings.outer.teeth,
            outerPalette,
            alpha or 1,
            gearType == "momma" and 8 or 6,
            gearType == "momma" and "heavy" or "classic"
        )
        DrawProceduralGear(
            vg,
            radius * rings.inner.radiusScale,
            rings.inner.teeth,
            innerPalette,
            alpha or 1,
            gearType == "momma" and 6 or 4,
            "classic"
        )
    else
        local visualStyle = gearType == "small"
                and "triad"
            or gearType == "large"
                and "heavy"
            or "classic"
        DrawProceduralGear(
            vg,
            radius,
            definition.teeth,
            GEAR_PALETTES[gearType] or GEAR_PALETTES.small,
            alpha or 1,
            nil,
            visualStyle
        )
    end

    nvgRestore(vg)
end

function GearRenderer.DrawFaultIndicator(vg, indicator, effectPhase)
    if not indicator or indicator.visible ~= true then
        return
    end

    local pulse = 0.5 + 0.5 * math.sin((effectPhase or 0) * 6)
    local arrowX = indicator.screenX or 0
    local arrowY = indicator.screenY or 0
    local angle = indicator.angle or 0
    local label = indicator.reason or "机械故障"

    nvgSave(vg)
    nvgTranslate(vg, arrowX, arrowY)
    nvgRotate(vg, angle)

    nvgBeginPath(vg)
    nvgCircle(vg, 0, 0, 25 + pulse * 3)
    nvgFillColor(vg, nvgRGBA(255, 38, 35, math.floor(42 + pulse * 46)))
    nvgFill(vg)

    nvgBeginPath(vg)
    nvgMoveTo(vg, -23, -6)
    nvgLineTo(vg, 5, -6)
    nvgLineTo(vg, 5, -15)
    nvgLineTo(vg, 29, 0)
    nvgLineTo(vg, 5, 15)
    nvgLineTo(vg, 5, 6)
    nvgLineTo(vg, -23, 6)
    nvgClosePath(vg)
    nvgFillColor(vg, nvgRGBA(255, 42, 38, 255))
    nvgFill(vg)
    nvgStrokeColor(vg, nvgRGBA(63, 8, 8, 255))
    nvgStrokeWidth(vg, 3)
    nvgStroke(vg)
    nvgRestore(vg)

    if incomeFont_ >= 0 then
        local labelWidth = math.max(76, math.min(210, #label * 14 + 24))
        local labelX = arrowX - labelWidth * 0.5
        local labelY = arrowY - 43
        nvgBeginPath(vg)
        nvgRoundedRect(vg, labelX, labelY - 15, labelWidth, 27, 7)
        nvgFillColor(vg, nvgRGBA(62, 8, 9, 236))
        nvgFill(vg)
        nvgStrokeColor(vg, nvgRGBA(255, 70, 62, 245))
        nvgStrokeWidth(vg, 2)
        nvgStroke(vg)
        nvgFontFaceId(vg, incomeFont_)
        nvgFontSize(vg, 14)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(255, 232, 222, 255))
        nvgText(vg, arrowX, labelY - 1, label)
    end
end

function GearRenderer.DrawIncomePopup(
    vg,
    screenX,
    screenY,
    screenRadius,
    incomeText,
    animationProgress
)
    if incomeFont_ < 0 or incomeText == nil or incomeText == "" then
        return
    end

    local progress = math.max(0, math.min(1, animationProgress or 0))
    local appear = math.min(1, progress / 0.10)
    local fade = math.min(1, (1 - progress) / 0.32)
    local alpha = math.floor(255 * appear * fade)
    if alpha <= 4 then
        return
    end

    local text = incomeText
    if string.sub(text, 1, 1) ~= "+"
        and string.find(text, "矿石", 1, true) ~= 1 then
        text = "+￥" .. text
    end
    local popupX = screenX
    local popupY = screenY - screenRadius - 20 - progress * 30

    nvgSave(vg)
    nvgFontFaceId(vg, incomeFont_)
    nvgFontSize(vg, 15)
    nvgTextAlign(vg, 18)
    nvgFillColor(vg, nvgRGBA(5, 8, 12, math.floor(alpha * 0.98)))
    local outline = 1.4
    nvgText(vg, popupX - outline, popupY, text)
    nvgText(vg, popupX + outline, popupY, text)
    nvgText(vg, popupX, popupY - outline, text)
    nvgText(vg, popupX, popupY + outline, text)
    nvgText(vg, popupX - 1, popupY - 1, text)
    nvgText(vg, popupX + 1, popupY - 1, text)
    nvgText(vg, popupX - 1, popupY + 1, text)
    nvgText(vg, popupX + 1, popupY + 1, text)

    nvgFillColor(vg, nvgRGBA(255, 218, 82, alpha))
    nvgText(vg, popupX - 0.35, popupY, text)
    nvgText(vg, popupX + 0.35, popupY, text)
    nvgRestore(vg)
end

return GearRenderer
