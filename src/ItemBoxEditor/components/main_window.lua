local i18n = require("ItemBoxEditor.i18n")
local state = require("ItemBoxEditor.state")
local dataHelper = require("ItemBoxEditor.data_helper")
local config = require("ItemBoxEditor.config")
local coreApi = require("ItemBoxEditor.utils")

local M = {}

local newSetMoney = 0
local newSetPts = 0
local isReadItemBox = false

local function withRange(label, maxVal)
    return label .. " (0~" .. tostring(maxVal) .. ")"
end

local function isInRange(val, minVal, maxVal)
    return val >= minVal and val <= maxVal
end

local function isNameLegal(name)
    return name ~= nil and
        utf8.len(tostring(name)) > 0 and
        utf8.len(tostring(name)) <= config.NAME_LENGTH_MAX
end

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
    if imgui.begin_window(
            i18n.getUIText("windowTitle"),
            state.userConfig.mainWindowOpen,
            config.IMGUI_AUTO_RESIZE
        ) then
        if imgui.begin_table("table_backup_warning", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.text_colored(i18n.getUIText("backupSaveWarning"), config.ERROR_COLOR)
            imgui.end_table()
        end

        if imgui.begin_table("table_read_box_btn", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            if imgui.button(i18n.getUIText("readItemBoxBtn"), { -0.001, 50 }) then
                coreApi.executeUserCmd(function()
                    coreApi.log("readItemBoxBtn clicked")
                    dataHelper.getItemBoxInfo()
                    dataHelper.getMoneyAndPts()
                    state.newHunterName = ""
                    state.newOtomoName = ""
                    isReadItemBox = true
                end)
            end
            imgui.end_table()
        end
        imgui.new_line()

        imgui.begin_disabled(not isReadItemBox)
        if imgui.begin_table("table_edit_item_title", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.text(i18n.getUIText("changeItemNumTitle"))
            imgui.end_table()
        end

        if imgui.begin_table("table_item_filters", 2, config.IMGUI_TABLE_NONE) then
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 1)
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 1)

            imgui.table_next_column()
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
            imgui.table_next_column()
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
            imgui.end_table()
        end

        if imgui.begin_table("table_item_combo", 1, config.IMGUI_TABLE_NONE) then
            local selectedItemComboChanged = false
            imgui.table_next_column()
            selectedItemComboChanged, state.currentSelectedItemIdx = imgui.combo(
                i18n.getUIText("changeItemNumCombox"),
                state.currentSelectedItemIdx,
                state.itemCombo.displayText
            )
            if selectedItemComboChanged then
                state.currentInputItemNewNum = state.itemCombo.itemNum[state.currentSelectedItemIdx]
            end
            imgui.end_table()
        end

        if imgui.begin_table("table_item_amount_btns", 2, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.begin_disabled(state.currentInputItemNewNum == 0)
            if imgui.button(i18n.getUIText("setMinLabel") .. "##itemSetMinBtn", { -0.001, 40 }) then
                state.currentInputItemNewNum = 0
            end
            imgui.end_disabled()

            imgui.table_next_column()
            imgui.begin_disabled(state.currentInputItemNewNum == config.ITEM_NUM_MAX)
            if imgui.button(i18n.getUIText("setMaxFormat", config.ITEM_NUM_MAX) .. "##itemSetMaxBtn", { -0.001, 40 }) then
                state.currentInputItemNewNum = config.ITEM_NUM_MAX
            end
            imgui.end_disabled()
            imgui.end_table()
        end

        local isItemNumInputValid = true
        if imgui.begin_table("table_item_amount_input", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            local itemNumInputChanged = false
            local itemNumInputStr = tostring(state.currentInputItemNewNum)
            itemNumInputChanged, itemNumInputStr = imgui.input_text(
                withRange(i18n.getUIText("changeItemNumInput"), config.ITEM_NUM_MAX),
                itemNumInputStr
            )

            local parsedNum = tonumber(itemNumInputStr)
            if parsedNum ~= nil and math.floor(parsedNum) == parsedNum and parsedNum >= 0 and parsedNum <= config.ITEM_NUM_MAX then
                if itemNumInputChanged then
                    state.currentInputItemNewNum = parsedNum
                end
            else
                isItemNumInputValid = false
            end

            if not isItemNumInputValid then
                imgui.text_colored(withRange(i18n.getUIText("changeItemNumInputError"), config.ITEM_NUM_MAX),
                    config.ERROR_COLOR)
            end
            imgui.end_table()
        end

        imgui.begin_disabled(not isItemNumInputValid)
        if imgui.begin_table("table_item_confirm_btn", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            if imgui.button(i18n.getUIText("changeItemNumBtn"), { -0.001, 40 }) then
                coreApi.executeUserCmd(function()
                    coreApi.log("changeItemNumBtn clicked")
                    dataHelper.changeItemNum(
                        state.itemCombo.cData[state.currentSelectedItemIdx].id,
                        state.currentInputItemNewNum - state.itemCombo.itemNum[state.currentSelectedItemIdx]
                    )
                end)
            end
            imgui.end_table()
        end
        imgui.end_disabled()

        imgui.new_line()

        if imgui.begin_table("table_money_pts_title", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.text(i18n.getUIText("coinAndPtsEditorTitle"))
            imgui.end_table()
        end

        if state.syncMoneyStr ~= tostring(state.currentMoney) then
            state.syncMoneyStr = tostring(state.currentMoney)
            newSetMoney = tonumber(state.currentMoney) or 0
        end

        if imgui.begin_table("table_money_current", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.text(i18n.getUIText("coinCurrentLabel") ..
                tostring(state.currentMoney) .. "   ->   " .. i18n.getUIText("coinNewLabel") .. tostring(newSetMoney))
            imgui.end_table()
        end

        local isMoneyInputValid = true
        if imgui.begin_table("table_money_edit", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            local moneyInputChanged = false
            local moneyInputStr = tostring(newSetMoney)
            moneyInputChanged, moneyInputStr = imgui.input_text(
                withRange(i18n.getUIText("coinInput"), config.MONEY_PTS_MAX) .. "##money_input",
                moneyInputStr
            )

            local parsedMoney = tonumber(moneyInputStr)
            if parsedMoney ~= nil and math.floor(parsedMoney) == parsedMoney and parsedMoney >= 0 and parsedMoney <= config.MONEY_PTS_MAX then
                if moneyInputChanged then
                    newSetMoney = parsedMoney
                end
            else
                isMoneyInputValid = false
            end

            if not isMoneyInputValid then
                imgui.text_colored(withRange(i18n.getUIText("coinInputError"), config.MONEY_PTS_MAX),
                    config.ERROR_COLOR)
            end
            imgui.end_table()
        end

        imgui.begin_disabled(not isMoneyInputValid)
        if imgui.begin_table("table_money_edit_btn_group_add", #config.MONEY_PTS_ADD_VALUES, config.IMGUI_TABLE_NONE) then
            for btnIdx = 1, #config.MONEY_PTS_ADD_VALUES do
                imgui.table_next_column()
                imgui.begin_disabled(
                    not isInRange(
                        newSetMoney + config.MONEY_PTS_ADD_VALUES[btnIdx],
                        0,
                        config.MONEY_PTS_MAX)
                )
                if imgui.button("+" .. tostring(config.MONEY_PTS_ADD_VALUES[btnIdx]) .. "##money_add_btn_" .. tostring(btnIdx), { -0.001, 40 }) then
                    newSetMoney = newSetMoney + config.MONEY_PTS_ADD_VALUES[btnIdx]
                end
                imgui.end_disabled()
            end
            imgui.end_table()
        end

        if imgui.begin_table("table_money_edit_btn_group_sub", #config.MONEY_PTS_ADD_VALUES, config.IMGUI_TABLE_NONE) then
            for btnIdx = 1, #config.MONEY_PTS_ADD_VALUES do
                imgui.table_next_column()
                imgui.begin_disabled(
                    not isInRange(
                        newSetMoney - config.MONEY_PTS_ADD_VALUES[btnIdx],
                        0,
                        config.MONEY_PTS_MAX)
                )
                if imgui.button("-" .. tostring(config.MONEY_PTS_ADD_VALUES[btnIdx]) .. "##money_sub_btn_" .. tostring(btnIdx), { -0.001, 40 }) then
                    newSetMoney = newSetMoney - config.MONEY_PTS_ADD_VALUES[btnIdx]
                end
                imgui.end_disabled()
            end
            imgui.end_table()
        end

        if imgui.begin_table("table_money_confirm_btn", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.begin_disabled(not isInRange(newSetMoney, 0, config.MONEY_PTS_MAX))
            if imgui.button(i18n.getUIText("coinSetBtn"), { -0.001, 40 }) then
                coreApi.executeUserCmd(function()
                    coreApi.log("coinSetBtn clicked")
                    dataHelper.changeMoneyAndPts(
                        1,
                        newSetMoney - tonumber(state.currentMoney)
                    )
                end)
            end
            imgui.end_disabled()
            imgui.end_table()
        end
        imgui.end_disabled()

        imgui.new_line()

        if state.syncPtsStr ~= tostring(state.currentPts) then
            state.syncPtsStr = tostring(state.currentPts)
            newSetPts = tonumber(state.currentPts) or 0
        end

        if imgui.begin_table("table_pts_current", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.text(i18n.getUIText("ptsCurrentLabel") ..
                tostring(state.currentPts) .. "   ->   " .. i18n.getUIText("ptsNewLabel") .. tostring(newSetPts))
            imgui.end_table()
        end

        local isPtsInputValid = true
        if imgui.begin_table("table_pts_edit", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            local ptsInputChanged = false
            local ptsInputStr = tostring(newSetPts)
            ptsInputChanged, ptsInputStr = imgui.input_text(
                withRange(i18n.getUIText("ptsInput"), config.MONEY_PTS_MAX) .. "##pts_input",
                ptsInputStr
            )

            local parsedPts = tonumber(ptsInputStr)
            if parsedPts ~= nil and math.floor(parsedPts) == parsedPts and parsedPts >= 0 and parsedPts <= config.MONEY_PTS_MAX then
                if ptsInputChanged then
                    newSetPts = parsedPts
                end
            else
                isPtsInputValid = false
            end

            if not isPtsInputValid then
                imgui.text_colored(withRange(i18n.getUIText("ptsInputError"), config.MONEY_PTS_MAX),
                    config.ERROR_COLOR)
            end
            imgui.end_table()
        end

        imgui.begin_disabled(not isPtsInputValid)
        if imgui.begin_table("table_pts_edit_btn_group_add", #config.MONEY_PTS_ADD_VALUES, config.IMGUI_TABLE_NONE) then
            for btnIdx = 1, #config.MONEY_PTS_ADD_VALUES do
                imgui.table_next_column()
                imgui.begin_disabled(
                    not isInRange(
                        newSetPts + config.MONEY_PTS_ADD_VALUES[btnIdx],
                        0,
                        config.MONEY_PTS_MAX)
                )
                if imgui.button("+" .. tostring(config.MONEY_PTS_ADD_VALUES[btnIdx]) .. "##pts_add_btn_" .. tostring(btnIdx), { -0.001, 40 }) then
                    newSetPts = newSetPts + config.MONEY_PTS_ADD_VALUES[btnIdx]
                end
                imgui.end_disabled()
            end
            imgui.end_table()
        end

        if imgui.begin_table("table_pts_edit_btn_group_sub", #config.MONEY_PTS_ADD_VALUES, config.IMGUI_TABLE_NONE) then
            for btnIdx = 1, #config.MONEY_PTS_ADD_VALUES do
                imgui.table_next_column()
                imgui.begin_disabled(
                    not isInRange(
                        newSetPts - config.MONEY_PTS_ADD_VALUES[btnIdx],
                        0,
                        config.MONEY_PTS_MAX)
                )
                if imgui.button("-" .. tostring(config.MONEY_PTS_ADD_VALUES[btnIdx]) .. "##pts_sub_btn_" .. tostring(btnIdx), { -0.001, 40 }) then
                    newSetPts = newSetPts - config.MONEY_PTS_ADD_VALUES[btnIdx]
                end
                imgui.end_disabled()
            end
            imgui.end_table()
        end

        if imgui.begin_table("table_pts_confirm_btn", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.begin_disabled(not isInRange(newSetPts, 0, config.MONEY_PTS_MAX))
            if imgui.button(i18n.getUIText("ptsSetBtn"), { -0.001, 40 }) then
                coreApi.executeUserCmd(function()
                    coreApi.log("ptsSetBtn clicked")
                    dataHelper.changeMoneyAndPts(
                        2,
                        newSetPts - tonumber(state.currentPts)
                    )
                end)
            end
            imgui.end_disabled()
            imgui.end_table()
        end
        imgui.end_disabled()

        imgui.new_line()

        if imgui.begin_table("table_name_reset_title", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.text(i18n.getUIText("nameResetTitle"))
            imgui.text_colored(i18n.getUIText("nameNgWordWarning"), config.ERROR_COLOR)
            imgui.text_colored(i18n.getUIText("nameResetReloadGameTip"), config.TIPS_COLOR)
            imgui.end_table()
        end

        local isHunterNameValid = isNameLegal(state.newHunterName)
        if imgui.begin_table("table_hunter_name_input", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            local hunterNameInputChanged = false
            local hunterNameInputStr = tostring(state.newHunterName or "")
            hunterNameInputChanged, hunterNameInputStr = imgui.input_text(
                i18n.getUIText("hunterName") .. "##hunter_name_input",
                hunterNameInputStr
            )
            if hunterNameInputChanged then
                state.newHunterName = hunterNameInputStr
                isHunterNameValid = isNameLegal(state.newHunterName)
            end
            if not isHunterNameValid then
                imgui.text_colored(i18n.getUIText("hunterNameMaxLengthWarning"), config.ERROR_COLOR)
            end
            imgui.end_table()
        end

        imgui.begin_disabled(not isHunterNameValid)
        if imgui.begin_table("table_hunter_name_confirm_btn", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            if imgui.button(i18n.getUIText("hunterNameResetBtn"), { -0.001, 40 }) then
                coreApi.executeUserCmd(function()
                    coreApi.log("hunterNameResetBtn clicked")
                    dataHelper.resetHunterName(state.newHunterName)
                end)
            end
            imgui.end_table()
        end
        imgui.end_disabled()

        imgui.new_line()

        local isOtomoNameValid = isNameLegal(state.newOtomoName)
        if imgui.begin_table("table_otomo_name_input", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            local otomoNameInputChanged = false
            local otomoNameInputStr = tostring(state.newOtomoName or "")
            otomoNameInputChanged, otomoNameInputStr = imgui.input_text(
                i18n.getUIText("otomoName") .. "##otomo_name_input",
                otomoNameInputStr
            )
            if otomoNameInputChanged then
                state.newOtomoName = otomoNameInputStr
                isOtomoNameValid = isNameLegal(state.newOtomoName)
            end
            if not isOtomoNameValid then
                imgui.text_colored(i18n.getUIText("otomoNameMaxLengthWarning"), config.ERROR_COLOR)
            end
            imgui.end_table()
        end

        imgui.begin_disabled(not isOtomoNameValid)
        if imgui.begin_table("table_otomo_name_confirm_btn", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            if imgui.button(i18n.getUIText("otomoNameResetBtn"), { -0.001, 40 }) then
                coreApi.executeUserCmd(function()
                    coreApi.log("otomoNameResetBtn clicked")
                    dataHelper.resetOtomoName(state.newOtomoName)
                end)
            end
            imgui.end_table()
        end
        imgui.end_disabled()

        imgui.end_disabled()

        imgui.new_line()

        if imgui.begin_table("table_repo_info", 1, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            imgui.text(i18n.getUIText("modRepoTitle"))
            imgui.end_table()
        end

        if imgui.begin_table("table_repo_info", 2, config.IMGUI_TABLE_NONE) then
            imgui.table_next_column()
            if imgui.button(
                    "Github:" .. i18n.getUIText("cpToClipboardBtn") .. "##mod_repo",
                    { -0.001, 40 }
                ) then
                sdk.copy_to_clipboard(i18n.getUIText("modRepo"))
            end
            imgui.table_next_column()
            if imgui.button(
                    "NexusMod:" .. i18n.getUIText("cpToClipboardBtn") .. "##mod_nexus",
                    { -0.001, 40 }) then
                sdk.copy_to_clipboard(i18n.getUIText("nexusModPage")
                )
            end
            imgui.end_table()
        end

        imgui.end_window()
    else
        state.userConfig.mainWindowOpen = false
        dataHelper.saveUserConfigJson(config.USER_CONFIG_PATH)
    end
end

return M
