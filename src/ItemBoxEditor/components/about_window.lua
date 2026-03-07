local i18n = require("ItemBoxEditor.i18n")
local config = require("ItemBoxEditor.config")
local state = require("ItemBoxEditor.state")
local dataHelper = require("ItemBoxEditor.data_helper")

local M = {}

function M.aboutWindow()
    if imgui.begin_window(
            i18n.getUIText("aboutWindowsTitle"),
            state.userConfig.aboutWindowOpen,
            config.IMGUI_AUTO_RESIZE
        ) then
        imgui.text(i18n.getUIText("modContributorTitle"))
        local contributorsStr = ""
        for i = 1, #i18n.getUIText("modContributors") do
            contributorsStr = contributorsStr .. i18n.getUIText("modContributors")[i]
            if i ~= #i18n.getUIText("modContributors") then
                contributorsStr = contributorsStr .. ", "
            end
        end
        imgui.text(contributorsStr)

        imgui.new_line()
        imgui.text(i18n.getUIText("modLicenseTitle"))
        imgui.text(i18n.getUIText("modLicenseContent"))

        imgui.new_line()
        imgui.text(i18n.getUIText("modRepoTitle"))
        if imgui.button(
                "Github:" .. i18n.getUIText("cpToClipboardBtn") .. "##mod_repo",
                { -0.001, 40 }
            ) then
            sdk.copy_to_clipboard(i18n.getUIText("modRepo"))
        end
        if imgui.button(
                "NexusMod:" .. i18n.getUIText("cpToClipboardBtn") .. "##mod_nexus",
                { -0.001, 40 }) then
            sdk.copy_to_clipboard(i18n.getUIText("nexusModPage")
            )
        end

        imgui.new_line()
        imgui.text(i18n.getUIText("otherLibsLicenseTitle"))
        imgui.new_line()
        imgui.text(i18n.getUIText("reframeworkLicenseTitle"))
        imgui.text(i18n.getUIText("reframeworkLicense"))

        imgui.end_window()
    else
        state.userConfig.aboutWindowOpen = false
        dataHelper.saveUserConfigJson(config.USER_CONFIG_PATH)
    end
end

return M
