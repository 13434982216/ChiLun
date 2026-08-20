local LoadingScreen = {}

local CONFIG = {
    minimumSeconds = 1.25,
    assetsPerFrame = 3,
    maxRetries = 5,
}

local active_ = false
local elapsed_ = 0
local assetIndex_ = 1
local assetRetries_ = 0
local root_ = nil
local statusLabel_ = nil
local percentLabel_ = nil
local progressBar_ = nil
local options_ = nil

local IMAGE_PATHS = {
    "image/home_landscape_factory_blueprint_bg_20260818094330.png",
    "image/home_title_frame_wide_v3_trimmed.png",
    "image/home_factory_button_panel_final.png",
    "image/home_leaderboard_button_panel_final.png",
    "image/home_factory_entry_icon_20260818094329.png",
    "image/home_leaderboard_entry_icon_20260818094318.png",
    "image/home_leaderboard_frame_wide_v2_trimmed.png",
    "image/ui_coin_brass_comic_20260807004421.png",
    "image/ui_essence_core_comic_20260807004430.png",
    "image/ui_torque_bolt_comic_20260807004422.png",
    "image/gear_workshop_home_hud_icon_20260817122607.png",
    "image/hud_b_extracted/permanent.png",
    "image/locked_question_gear_comic_20260817094517.png",
    "image/hud_b_extracted/shaft.png",
    "image/hud_b_extracted/income.png",
    "image/hud_b_extracted/click.png",
    "image/hud_b_extracted/modify.png",
    "image/gear_main_comic_exact.png",
    "image/gear_small_comic_exact.png",
    "image/gear_medium_comic_exact.png",
    "image/gear_large_comic_exact.png",
    "image/gear_compound_comic_exact.png",
    "image/gear_momma_comic_exact.png",
    "image/gear_coin_large_comic_20260811093509.png",
    "image/ui_blueprint_clean/panel_left.png",
    "image/ui_blueprint_clean/panel_right.png",
    "image/ui_blueprint_clean/card_shop.png",
    "image/ui_blueprint_clean/card_upgrade.png",
    "image/ui_blueprint_clean/handle_left.png",
    "image/ui_blueprint_clean/handle_right.png",
    "image/ui_blueprint_clean/top_hud_frame.png",
}

local function CreateUI()
    local UI = options_.ui
    statusLabel_ = UI.Label {
        text = "正在准备工坊资源...",
        fontSize = 18,
        fontColor = { 166, 211, 226, 255 },
        textAlign = "center",
    }
    percentLabel_ = UI.Label {
        text = "0%",
        fontSize = 16,
        fontWeight = "bold",
        fontColor = { 248, 191, 72, 255 },
        textAlign = "center",
    }
    progressBar_ = UI.ProgressBar {
        value = 0,
        max = 1,
        width = "100%",
        height = 18,
        showLabel = false,
        backgroundColor = { 8, 25, 38, 255 },
        borderColor = { 66, 171, 207, 255 },
        borderWidth = 2,
        borderRadius = 0,
        fillGradient = {
            direction = "to-right",
            from = { 184, 112, 28, 255 },
            to = { 255, 214, 88, 255 },
        },
    }

    root_ = UI.Panel {
        width = "100%",
        height = "100%",
        pointerEvents = "auto",
        justifyContent = "center",
        alignItems = "center",
        backgroundGradient = {
            type = "linear",
            direction = "to-bottom",
            from = { 4, 12, 23, 255 },
            to = { 6, 37, 57, 255 },
        },
        children = {
            UI.Panel {
                width = "78%",
                maxWidth = 720,
                minWidth = 300,
                padding = 28,
                gap = 16,
                alignItems = "center",
                backgroundColor = { 8, 26, 40, 248 },
                borderColor = { 55, 171, 207, 255 },
                borderWidth = { 2, 4, 5, 2 },
                borderRadius = 0,
                boxShadow = {
                    { x = 8, y = 8, blur = 0, color = { 0, 0, 0, 90 } },
                },
                children = {
                    UI.Label {
                        text = "齿轮工坊",
                        fontSize = 38,
                        fontWeight = "bold",
                        fontColor = { 255, 213, 105, 255 },
                        textAlign = "center",
                        textStroke = {
                            width = 2,
                            color = { 56, 29, 7, 255 },
                        },
                    },
                    UI.Label {
                        text = "机械系统启动中",
                        fontSize = 14,
                        fontWeight = "bold",
                        letterSpacing = 3,
                        fontColor = { 79, 210, 241, 255 },
                        textAlign = "center",
                    },
                    UI.Divider {
                        width = "100%",
                        thickness = 2,
                        color = { 31, 111, 145, 220 },
                        spacing = 2,
                    },
                    statusLabel_,
                    UI.Panel {
                        width = "100%",
                        height = 18,
                        children = { progressBar_ },
                    },
                    percentLabel_,
                    UI.Label {
                        text = "正在校准齿轮与动力装置，请稍候",
                        fontSize = 12,
                        fontColor = { 116, 157, 174, 255 },
                        textAlign = "center",
                    },
                },
            },
        },
    }
    UI.SetRoot(root_)
    print(string.format("[Loading] 独立加载页面已显示: assets=%d", #IMAGE_PATHS))
end

local function Finish()
    active_ = false
    statusLabel_:SetText("工坊准备完成")
    percentLabel_:SetText("100%")
    progressBar_:SetValue(1)

    if root_ then
        root_:Destroy()
        root_ = nil
    end
    statusLabel_ = nil
    percentLabel_ = nil
    progressBar_ = nil

    local onComplete = options_.onComplete
    options_ = nil
    print("[Loading] 资源句柄已就绪")
    if onComplete then
        onComplete()
    end
end

function LoadingScreen.Start(options)
    options_ = options
    active_ = true
    elapsed_ = 0
    assetIndex_ = 1
    assetRetries_ = 0
    CreateUI()
end

function LoadingScreen.Update(timeStep)
    if not active_ then
        return
    end

    elapsed_ = elapsed_ + math.max(timeStep, 0)
    local imageCache = options_.imageCache
    local total = #IMAGE_PATHS
    local loadedThisFrame = 0
    while assetIndex_ <= total and loadedThisFrame < CONFIG.assetsPerFrame do
        local path = IMAGE_PATHS[assetIndex_]
        imageCache.Release(path)
        local handle = imageCache.Get(path)
        if not handle or handle <= 0 then
            assetRetries_ = assetRetries_ + 1
            statusLabel_:SetText(string.format(
                "素材加载失败，正在重试 (%d/%d)",
                assetRetries_,
                CONFIG.maxRetries
            ))
            print(string.format(
                "[Loading] ERROR: 素材句柄创建失败: index=%d retry=%d/%d path=%s",
                assetIndex_, assetRetries_, CONFIG.maxRetries, path
            ))
            if assetRetries_ >= CONFIG.maxRetries then
                print(string.format(
                    "[Loading] WARNING: 跳过无法加载的素材，继续进入游戏: path=%s",
                    path
                ))
                assetIndex_ = assetIndex_ + 1
                assetRetries_ = 0
                loadedThisFrame = loadedThisFrame + 1
            end
            return
        end
        assetRetries_ = 0
        print(string.format(
            "[Loading] 素材已就绪: %d/%d path=%s handle=%s",
            assetIndex_, total, path, tostring(handle)
        ))
        assetIndex_ = assetIndex_ + 1
        loadedThisFrame = loadedThisFrame + 1
    end

    local completed = math.min(total, assetIndex_ - 1)
    local progress = total > 0 and completed / total or 1
    statusLabel_:SetText(string.format("正在装配素材  %d / %d", completed, total))
    percentLabel_:SetText(string.format("%d%%", math.floor(progress * 100 + 0.5)))
    progressBar_:SetValue(progress)

    if assetIndex_ > total and elapsed_ >= CONFIG.minimumSeconds then
        Finish()
    end
end

function LoadingScreen.IsActive()
    return active_
end

return LoadingScreen
