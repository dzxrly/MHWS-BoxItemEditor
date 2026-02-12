local config = require("ItemBoxEditor.config")
local state = require("ItemBoxEditor.state")
local utils = require("ItemBoxEditor.utils")
local data_ops = require("ItemBoxEditor.data_ops")
local data_loader = require("ItemBoxEditor.data_loader")
local ui_helpers = require("ItemBoxEditor.ui_helpers")

local M = {}

local function withRange(label, maxVal)
    return label .. " (0~" .. tostring(maxVal) .. ")"
end

function M.renderItemBoxEditorSection()
    imgui.new_line()
    imgui.text_colored(state.i18n.itemIdFileTip, config.TIPS_COLOR)
    imgui.text(state.i18n.changeItemNumTitle)
    imgui.set_next_item_width(config.WINDOW_WIDTH_S)
    state.typeFilterComboChanged, state.filterSetting.filterIndex = imgui.combo(
            state.i18n.changeItemNumFilterItemType,
            state.filterSetting.filterIndex, state.typeFilterLabel)
    imgui.same_line()
    imgui.set_next_item_width(config.WINDOW_WIDTH_S)
    state.rareFilterComboChanged, state.filterSetting.rareIndex = imgui.combo(
            state.i18n.changeItemNumFilterItemRare,
            state.filterSetting.rareIndex, state.rareFilterLabel)
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.itemBoxInputChanged, state.filterSetting.searchStr = imgui.input_text(state.i18n.searchInput,
            state.filterSetting.searchStr)

    if state.rareFilterComboChanged then
        ui_helpers.refreshItemBoxSearch()
    end

    if state.typeFilterComboChanged then
        ui_helpers.refreshItemBoxSearch()
    end

    if state.itemBoxInputChanged then
        ui_helpers.refreshItemBoxSearch()
    end

    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.itemBoxComboChanged, state.itemBoxComboIndex = imgui.combo(state.i18n.changeItemNumCombox,
            state.itemBoxComboIndex,
            state.itemBoxSearchedLabels)
    if state.itemBoxComboChanged then
        ui_helpers.setItemBoxSelectionByIndex(state.itemBoxComboIndex)
    end
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.itemBoxSliderChanged, state.itemBoxSliderNewVal = imgui.slider_int(
            withRange(state.i18n.changeItemNumSlider, config.ITEM_NUM_MAX),
            state.itemBoxSelectedItemNum, 0, config.ITEM_NUM_MAX)
    if state.itemBoxSliderChanged then
        state.itemBoxSelectedItemNum = state.itemBoxSliderNewVal
        state.itemBoxInputCountNewVal = tostring(state.itemBoxSliderNewVal)
        if utils.checkIntegerInRange(state.itemBoxSliderNewVal, 0, config.ITEM_NUM_MAX) then
            state.itemBoxConfirmBtnEnabled = true
        else
            state.itemBoxConfirmBtnEnabled = false
        end
    end
    if imgui.button(state.i18n.setMinLabel .. "##item", config.SMALL_BTN) then
        state.itemBoxSelectedItemNum = 0
        state.itemBoxInputCountNewVal = "0"
    end
    imgui.same_line()
    if imgui.button(string.format(state.i18n.setMaxFormat, tostring(config.ITEM_NUM_MAX)) .. "##item",
            config.SMALL_BTN) then
        state.itemBoxSelectedItemNum = config.ITEM_NUM_MAX
        state.itemBoxInputCountNewVal = tostring(config.ITEM_NUM_MAX)
    end
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.itemBoxInputCountChanged, state.itemBoxInputCountNewVal = imgui.input_text(
            withRange(state.i18n.changeItemNumInput, config.ITEM_NUM_MAX),
            state.itemBoxInputCountNewVal)
    if state.itemBoxInputCountChanged then
        local num = utils.checkIntegerInRange(state.itemBoxInputCountNewVal, 0, config.ITEM_NUM_MAX)
        if num then
            state.itemBoxConfirmBtnEnabled = true
            state.itemBoxSelectedItemNum = num
            state.itemBoxSliderNewVal = num
        else
            state.itemBoxConfirmBtnEnabled = false
        end
    end
    imgui.text_colored(state.i18n.changeItemTip, config.TIPS_COLOR)
    imgui.text_colored(state.i18n.changeItemWarning, config.ERROR_COLOR)
    imgui.begin_disabled(state.itemBoxSearchedItems == nil or #state.itemBoxSearchedItems == 0 or
            state.itemBoxSelectedItemFixedId ==
                    nil or not state.itemBoxConfirmBtnEnabled)
    if imgui.button(state.i18n.changeItemNumBtn, config.SMALL_BTN) then
        data_ops.changeBoxItemNum(state.itemBoxSelectedItemFixedId, state.itemBoxSelectedItemNum)
    end
    imgui.end_disabled()
    local errDisplay = ""
    if not state.itemBoxConfirmBtnEnabled then
        errDisplay = withRange(state.i18n.changeItemNumInputError, config.ITEM_NUM_MAX)
    else
        errDisplay = ""
    end
    imgui.text_colored(errDisplay, config.ERROR_COLOR)
end

function M.renderMoneyAndPointsSection()
    imgui.text(state.i18n.coinAndPtsEditorTitle)
    local isCooldown = os.clock() < state.moneyPtsNextAllowed

    -- Money section
    imgui.text(state.i18n.coinCounterVal .. ": " .. tostring(state.originMoney))
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.moneySliderChanged, state.moneySliderVal = imgui.slider_int(
            withRange(state.i18n.coinSlider, config.MONEY_PTS_MAX),
            state.moneySliderVal, 0, config.MONEY_PTS_MAX)
    if state.moneySliderChanged then
        state.moneyInputVal = tostring(state.moneySliderVal)
        state.moneyInputValid = true
    end
    if imgui.button(state.i18n.setMinLabel .. "##money", config.SMALL_BTN) then
        state.moneySliderVal = 0
        state.moneyInputVal = "0"
        state.moneyInputValid = true
    end
    imgui.same_line()
    if imgui.button(string.format(state.i18n.setMaxFormat, tostring(config.MONEY_PTS_MAX)) .. "##money",
            config.SMALL_BTN) then
        state.moneySliderVal = config.MONEY_PTS_MAX
        state.moneyInputVal = tostring(config.MONEY_PTS_MAX)
        state.moneyInputValid = true
    end
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.moneyInputChanged, state.moneyInputVal = imgui.input_text(
            withRange(state.i18n.coinInput, config.MONEY_PTS_MAX), state.moneyInputVal)
    if state.moneyInputChanged then
        local num = utils.checkIntegerInRange(state.moneyInputVal, 0, config.MONEY_PTS_MAX)
        if num then
            state.moneyInputValid = true
            state.moneySliderVal = num
        else
            state.moneyInputValid = false
        end
    end
    imgui.begin_disabled(isCooldown or not state.moneyInputValid or state.moneySliderVal == state.originMoney)
    if imgui.button(state.i18n.coinSetBtn, config.SMALL_BTN) then
        ui_helpers.trySetMoney(state.moneySliderVal)
    end
    imgui.end_disabled()
    if not state.moneyInputValid then
        imgui.text_colored(withRange(state.i18n.coinInputError, config.MONEY_PTS_MAX), config.ERROR_COLOR)
    end
    ui_helpers.renderAddButtons("money_add", state.originMoney, ui_helpers.tryApplyMoneyChange, isCooldown)
    ui_helpers.renderSubButtons("money_sub", state.originMoney, ui_helpers.tryApplyMoneySubChange, isCooldown)

    -- Points section
    imgui.new_line()
    imgui.text(state.i18n.ptsCounterVal .. ": " .. tostring(state.originPoints))
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.ptsSliderChanged, state.ptsSliderVal = imgui.slider_int(
            withRange(state.i18n.ptsSlider, config.MONEY_PTS_MAX),
            state.ptsSliderVal, 0, config.MONEY_PTS_MAX)
    if state.ptsSliderChanged then
        state.ptsInputVal = tostring(state.ptsSliderVal)
        state.ptsInputValid = true
    end
    if imgui.button(state.i18n.setMinLabel .. "##pts", config.SMALL_BTN) then
        state.ptsSliderVal = 0
        state.ptsInputVal = "0"
        state.ptsInputValid = true
    end
    imgui.same_line()
    if imgui.button(string.format(state.i18n.setMaxFormat, tostring(config.MONEY_PTS_MAX)) .. "##pts",
            config.SMALL_BTN) then
        state.ptsSliderVal = config.MONEY_PTS_MAX
        state.ptsInputVal = tostring(config.MONEY_PTS_MAX)
        state.ptsInputValid = true
    end
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.ptsInputChanged, state.ptsInputVal = imgui.input_text(
            withRange(state.i18n.ptsInput, config.MONEY_PTS_MAX), state.ptsInputVal)
    if state.ptsInputChanged then
        local num = utils.checkIntegerInRange(state.ptsInputVal, 0, config.MONEY_PTS_MAX)
        if num then
            state.ptsInputValid = true
            state.ptsSliderVal = num
        else
            state.ptsInputValid = false
        end
    end
    imgui.begin_disabled(isCooldown or not state.ptsInputValid or state.ptsSliderVal == state.originPoints)
    if imgui.button(state.i18n.ptsSetBtn, config.SMALL_BTN) then
        ui_helpers.trySetPoints(state.ptsSliderVal)
    end
    imgui.end_disabled()
    if not state.ptsInputValid then
        imgui.text_colored(withRange(state.i18n.ptsInputError, config.MONEY_PTS_MAX), config.ERROR_COLOR)
    end
    ui_helpers.renderAddButtons("pts_add", state.originPoints, ui_helpers.tryApplyPointsChange, isCooldown)
    ui_helpers.renderSubButtons("pts_sub", state.originPoints, ui_helpers.tryApplyPointsSubChange, isCooldown)
end

function M.renderNameResetSection()
    imgui.new_line()
    imgui.text(state.i18n.nameResetTitle)
    imgui.text_colored(state.i18n.nameNgWordWarning, config.ERROR_COLOR)
    imgui.text_colored(state.i18n.nameResetReloadGameTip, config.TIPS_COLOR)
    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.hunterNameInputChanged, state.newHunterName = imgui.input_text(state.i18n.hunterName, state.newHunterName)
    if state.hunterNameInputChanged then
        if state.newHunterName ~= nil and utf8.len(tostring(state.newHunterName)) > 0 and
                utf8.len(tostring(state.newHunterName)) <=
                        config.NAME_LENGTH_MAX then
            state.hunterNameResetBtnEnabled = true
        else
            state.hunterNameResetBtnEnabled = false
        end
        print(state.hunterNameResetBtnEnabled)
    end
    imgui.begin_disabled(not state.hunterNameResetBtnEnabled)
    if imgui.button(state.i18n.hunterNameResetBtn, config.LARGE_BTN) then
        data_ops.resetHunterName(state.cBasicParam, state.newHunterName)
    end
    imgui.end_disabled()
    if state.hunterNameResetBtnEnabled then
        imgui.text_colored("", config.TIPS_COLOR)
    else
        imgui.text_colored(state.i18n.hunterNameMaxLengthWarning, config.ERROR_COLOR)
    end

    imgui.set_next_item_width(config.WINDOW_WIDTH_M)
    state.otomoNameInputChanged, state.newOtomoName = imgui.input_text(state.i18n.otomoName, state.newOtomoName)
    if state.otomoNameInputChanged then
        if state.newOtomoName ~= nil and utf8.len(tostring(state.newOtomoName)) > 0 and
                utf8.len(tostring(state.newOtomoName)) <=
                        config.NAME_LENGTH_MAX then
            state.otomoNameResetBtnEnabled = true
        else
            state.otomoNameResetBtnEnabled = false
        end
    end
    imgui.begin_disabled(not state.otomoNameResetBtnEnabled)
    if imgui.button(state.i18n.otomoNameResetBtn, config.LARGE_BTN) then
        data_ops.resetOtomoName(state.cBasicParam, state.newOtomoName)
    end
    imgui.end_disabled()
    if state.otomoNameResetBtnEnabled then
        imgui.text_colored("", config.TIPS_COLOR)
    else
        imgui.text_colored(state.i18n.otomoNameMaxLengthWarning, config.ERROR_COLOR)
    end
end

function M.renderRepoLinksSection()
    imgui.text(state.i18n.modRepoTitle)
    imgui.text(state.i18n.modRepo)
    ui_helpers.renderCopyButton("Repo: " .. state.i18n.cpToClipboardBtn, state.i18n.modRepo)
    imgui.text(state.i18n.nexusModPage)
    ui_helpers.renderCopyButton("NexusMods: " .. state.i18n.cpToClipboardBtn, state.i18n.nexusModPage)
end

function M.mainWindow()
    if imgui.begin_window(state.i18n.windowTitle, state.mainWindowState, ImGuiWindowFlags_AlwaysAutoResize) then
        ui_helpers.renderVersionInfo()

        if imgui.button(state.i18n.readItemBoxBtn, config.LARGE_BTN) then
            data_loader.init()
        end
        imgui.new_line()

        ------------------- existed item change -----------------
        imgui.begin_disabled(state.cItemParam == nil)
        M.renderItemBoxEditorSection()
        imgui.end_disabled()

        imgui.new_line()
        imgui.begin_disabled(state.cBasicParam == nil)
        M.renderMoneyAndPointsSection()
        M.renderNameResetSection()
        imgui.end_disabled()

        imgui.new_line()
        M.renderRepoLinksSection()

        imgui.end_window()
    else
        state.clear()
        state.mainWindowState = false
        state.userConfig.mainWindowOpen = state.mainWindowState
        data_loader.saveUserConfigJson(config.USER_CONFIG_PATH)
    end
end

function M.itemTableWindow()
    local changed = nil
    imgui.set_next_window_size({ 480, 640 }, 4) -- 4 is ImGuiCond_FirstUseEver
    if imgui.begin_window(state.i18n.itemTableWindowTitle, state.itemWindowState,
            ImGuiWindowFlags_AlwaysAutoResize) then
        imgui.begin_table("search-group", 2, ImGuiTableFlags_NoSavedSettings)
        imgui.table_setup_column("", 0, 2)
        imgui.table_setup_column("", 0, 1)

        imgui.table_next_column()
        imgui.push_item_width(-1)
        local searchItem = state.searchItemTarget
        changed, searchItem = imgui.input_text("", state.searchItemTarget)
        imgui.pop_item_width()
        if changed then
            state.searchItemTarget = searchItem
        end

        imgui.table_next_column()
        if imgui.button(state.i18n.clearBtn, { -0.001, 0 }) then
            state.searchItemTarget = nil
            state.searchItemResult = utils.searchItemList(state.searchItemTarget)
        end
        imgui.end_table()

        if imgui.button(state.i18n.searchBtn, { -0.001, 0 }) then
            state.searchItemResult = utils.searchItemList(state.searchItemTarget)
        end

        imgui.begin_table("table", 2, 17) -- 17 is ImGuiTableFlags_Resizable | ImGuiTableFlags_NoSavedSettings

        imgui.table_setup_column("", 0, 1)
        imgui.table_setup_column("", 0, 2)

        imgui.push_style_color(21, 0xff142D65)
        imgui.push_style_color(22, 0xff142D65)
        imgui.push_style_color(23, 0xff142D65)
        imgui.table_next_column()
        imgui.button(state.i18n.itemTableTitleID, { -0.001, 0 })
        imgui.table_next_column()
        imgui.button(state.i18n.itemTableTitleName, { -0.001, 0 })
        imgui.pop_style_color(3)

        for i = 1, #state.searchItemResult do
            imgui.table_next_column()
            if imgui.button(state.searchItemResult[i].key, { -0.001, 0 }) then
                ui_helpers.selectItemInMainWindowByFixedId(state.searchItemResult[i].key)
            end
            imgui.table_next_column()
            if imgui.button(state.searchItemResult[i].value, { -0.001, 0 }) then
                ui_helpers.selectItemInMainWindowByFixedId(state.searchItemResult[i].key)
            end
        end

        imgui.end_table()

        imgui.end_window()
    else
        state.itemWindowState = false
        state.userConfig.itemWindowOpen = state.itemWindowState
        data_loader.saveUserConfigJson(config.USER_CONFIG_PATH)
    end
end

function M.aboutWindow()
    if imgui.begin_window(state.i18n.aboutWindowsTitle, state.aboutWindowState,
            ImGuiWindowFlags_AlwaysAutoResize) then
        imgui.text(state.i18n.modContributorTitle)
        local contributorsStr = ""
        for i = 1, #state.i18n.modContributors do
            contributorsStr = contributorsStr .. state.i18n.modContributors[i]
            if i ~= #state.i18n.modContributors then
                contributorsStr = contributorsStr .. ", "
            end
        end
        imgui.set_next_item_width(config.WINDOW_WIDTH_M)
        imgui.text(contributorsStr)

        imgui.new_line()
        imgui.text(state.i18n.modLicenseTitle)
        imgui.set_next_item_width(config.WINDOW_WIDTH_M)
        imgui.text(state.i18n.modLicenseContent)

        imgui.new_line()
        imgui.text(state.i18n.modRepoTitle)
        imgui.set_next_item_width(config.WINDOW_WIDTH_M)
        imgui.text(state.i18n.modRepo)
        ui_helpers.renderCopyButton("Repo: " .. state.i18n.cpToClipboardBtn, state.i18n.modRepo)
        imgui.text(state.i18n.nexusModPage)
        ui_helpers.renderCopyButton("NexusMods: " .. state.i18n.cpToClipboardBtn, state.i18n.nexusModPage)

        imgui.new_line()
        imgui.text(state.i18n.otherLibsLicenseTitle)
        imgui.new_line()
        imgui.text(state.i18n.reframeworkLicenseTitle)
        imgui.set_next_item_width(config.WINDOW_WIDTH_M)
        imgui.text(state.i18n.reframeworkLicense)

        imgui.end_window()
    else
        state.aboutWindowState = false
        state.userConfig.aboutWindowOpen = state.aboutWindowState
    end
end

return M
