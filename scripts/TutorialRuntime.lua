local TutorialUI = require("TutorialUI")

local TutorialRuntime = {
    Version = TutorialUI.Version,
    FirstStep = TutorialUI.FirstStep,
    LubricantFirstStep = TutorialUI.LubricantFirstStep,
}

function TutorialRuntime.Create(options)
    return TutorialUI.Create(options)
end

function TutorialRuntime.IsWebPreview()
    return type(GetPlatform) == "function"
        and GetPlatform() == "Web"
end

function TutorialRuntime.CheckTestAccount(cloud, key, state, onReady)
    if cloud == nil then
        state.tutorialTestAccount = false
        state.tutorialTestAccountChecked = true
        print("[TutorialTest] 当前环境无 clientCloud，按普通账号启动")
        onReady(false)
        return
    end

    print(string.format(
        "[TutorialTest] 检查账号标记: userId=%s",
        tostring(cloud.userId)
    ))
    cloud:Get(key, {
        ok = function(values)
            local isTestAccount = type(values) == "table"
                and values[key] == true
            state.tutorialTestAccount = isTestAccount
            state.tutorialTestAccountChecked = true
            print(string.format(
                "[TutorialTest] 账号标记读取完成: userId=%s enabled=%s",
                tostring(cloud.userId),
                tostring(isTestAccount)
            ))
            onReady(isTestAccount)
        end,
        error = function(code, reason)
            state.tutorialTestAccount = false
            state.tutorialTestAccountChecked = true
            print(string.format(
                "[TutorialTest] 账号标记读取失败 code=%s reason=%s，按普通账号启动",
                tostring(code),
                tostring(reason)
            ))
            onReady(false)
        end,
        timeout = function()
            state.tutorialTestAccount = false
            state.tutorialTestAccountChecked = true
            print("[TutorialTest] 账号标记读取超时，按普通账号启动")
            onReady(false)
        end,
    })
end

return TutorialRuntime
