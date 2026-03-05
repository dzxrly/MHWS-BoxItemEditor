local i18n = require("ItemBoxEditor.i18n")
local state = require("ItemBoxEditor.state")
local dataHelper = require("ItemBoxEditor.data_helper")
local config = require("ItemBoxEditor.config")
local coreApi = require("ItemBoxEditor.utils")

local M = {}

local function getFilterTypeComboObj()
    local filterTypeComboObj = {}
    table.insert(filterTypeComboObj, i18n.getUIText("filterNoLimitTitle") .. "##filterTypeComboObj")
    for i = 1, #i18n.getUIText("typeFilterComboLabel") do
        local text = i18n.getUIText("typeFilterComboLabel")[i]
        table.insert(filterTypeComboObj, text .. "##filterTypeComboObj_" .. i)
    end
    return filterTypeComboObj
end

local function getRareComboObj()
    local rareComboObj = {}
    table.insert(rareComboObj, i18n.getUIText("filterNoLimitTitle") .. "##rareComboObj")
    for i = 1, #state.rareEnum.content do
        table.insert(rareComboObj, state.rareEnum.content[i] .. "##rareComboObj_" .. i)
    end
    return rareComboObj
end

function M.mainWindow()
    if imgui.begin_window(i18n.getUIText("windowTitle"), state.userConfig.mainWindowOpen, ImGuiWindowFlags_AlwaysAutoResize) then
        imgui.text_colored(i18n.getUIText("backupSaveWarning"), config.ERROR_COLOR)

        if imgui.button(i18n.getUIText("readItemBoxBtn"), config.LARGE_BTN) then
            coreApi.executeUserCmd(function()
                coreApi.log("readItemBoxBtn clicked")
                dataHelper.initBaseItemList()
                dataHelper.getItemBoxInfo()
            end)
        end
        imgui.new_line()

        imgui.begin_disabled(#state.itemCombo.displayText == 0)
        imgui.text(i18n.getUIText("changeItemNumTitle"))

        imgui.set_next_item_width(config.WINDOW_WIDTH_S)
        local filterTypeComboChanged = false
        local filterTypeComboObj = getFilterTypeComboObj()
        filterTypeComboChanged, state.currentSelectedFilterTypeIdx = imgui.combo(
            i18n.getUIText("changeItemNumFilterItemType"),
            state.currentSelectedFilterTypeIdx,
            filterTypeComboObj
        )
        if filterTypeComboChanged then
            dataHelper.getItemBoxInfo()
        end
        imgui.same_line()
        imgui.set_next_item_width(config.WINDOW_WIDTH_S)
        local rareComboObj = getRareComboObj()
        local rareComboChanged = false
        rareComboChanged, state.currentSelectedRareIdx = imgui.combo(
            i18n.getUIText("changeItemNumFilterItemRare"),
            state.currentSelectedRareIdx,
            rareComboObj
        )
        if rareComboChanged then
            dataHelper.getItemBoxInfo()
        end

        imgui.set_next_item_width(config.WINDOW_WIDTH_M)
        local itemComboChanged = false
        itemComboChanged, state.currentSelectedItemIdx = imgui.combo(
            i18n.getUIText("changeItemNumCombox"),
            state.currentSelectedItemIdx,
            state.itemCombo.displayText
        )

        imgui.end_disabled()

        imgui.end_window()
    else
        state.userConfig.mainWindowOpen = false
        dataHelper.saveUserConfigJson(config.USER_CONFIG_PATH)
    end
end

function M.itemTableWindow()

end

function M.aboutWindow()

end

return M
