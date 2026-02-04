local config = require("ItemBoxEditor.config")
local state = require("ItemBoxEditor.state")
local utils = require("ItemBoxEditor.utils")
local data_ops = require("ItemBoxEditor.data_ops")

local M = {}

function M.consumeDebounce(nextAllowed)
    local now = os.clock()
    if now < nextAllowed then
        return false, nextAllowed
    end
    return true, now + config.CLICK_COOLDOWN_SEC
end

function M.refreshItemBoxSearch()
    state.itemBoxComboIndex = 1
    state.itemBoxSearchedItems, state.itemBoxSearchedLabels = utils.filterCombo(state.itemBoxList, state.filterSetting)
    if #state.itemBoxSearchedItems > 0 then
        state.itemBoxSelectedItemFixedId = state.itemBoxSearchedItems[1].fixedId
        state.itemBoxSelectedItemNum = state.itemBoxSearchedItems[1].num
    end
end

function M.setItemBoxSelectionByIndex(index)
    if state.itemBoxSearchedItems == nil or state.itemBoxSearchedItems[index] == nil then
        return
    end
    state.itemBoxSelectedItemFixedId = state.itemBoxSearchedItems[index].fixedId
    state.itemBoxSelectedItemNum = state.itemBoxSearchedItems[index].num
    state.itemBoxInputCountNewVal = tostring(state.itemBoxSelectedItemNum)
end

function M.renderAddButtons(labelPrefix, baseValue, applyFn, isCooldown)
    for i = 1, #config.MONEY_PTS_ADD_VALUES do
        local addValue = config.MONEY_PTS_ADD_VALUES[i]
        if i > 1 then
            imgui.same_line()
        end
        imgui.begin_disabled(isCooldown or baseValue + addValue > config.MONEY_PTS_MAX)
        if imgui.button(labelPrefix .. tostring(addValue), config.SMALL_BTN) then
            applyFn(addValue)
        end
        imgui.end_disabled()
    end
end

function M.renderSubButtons(labelPrefix, baseValue, applyFn, isCooldown)
    for i = 1, #config.MONEY_PTS_ADD_VALUES do
        local subValue = config.MONEY_PTS_ADD_VALUES[i]
        if i > 1 then
            imgui.same_line()
        end
        imgui.begin_disabled(isCooldown or baseValue - subValue < 0)
        if imgui.button(labelPrefix .. tostring(subValue), config.SMALL_BTN) then
            applyFn(subValue)
        end
        imgui.end_disabled()
    end
end

local function findItemIndexByFixedId(items, fixedId)
    if items == nil then
        return nil
    end
    local targetId = tonumber(fixedId) or fixedId
    for index = 1, #items do
        local currentId = tonumber(items[index].fixedId) or items[index].fixedId
        if currentId == targetId then
            return index
        end
    end
    return nil
end

function M.selectItemInMainWindowByFixedId(fixedId)
    if state.itemBoxList == nil or #state.itemBoxList == 0 then
        return
    end
    local targetId = tonumber(fixedId) or fixedId
    local index = findItemIndexByFixedId(state.itemBoxSearchedItems, targetId)
    if index == nil then
        state.filterSetting.filterIndex = 1
        state.filterSetting.rareIndex = 1
        state.filterSetting.searchStr = "[" .. tostring(targetId) .. "]"
        M.refreshItemBoxSearch()
        index = findItemIndexByFixedId(state.itemBoxSearchedItems, targetId)
    end
    if index ~= nil then
        state.itemBoxComboIndex = index
        M.setItemBoxSelectionByIndex(index)
    end
end

function M.tryApplyMoneyChange(diff)
    diff = tonumber(diff)
    if diff == nil or diff <= 0 then
        return
    end
    if state.originMoney + diff > config.MONEY_PTS_MAX then
        return
    end
    local allowed = false
    allowed, state.moneyPtsNextAllowed = M.consumeDebounce(state.moneyPtsNextAllowed)
    if not allowed then
        return
    end
    data_ops.moneyAddFunc(state.cBasicParam, diff)
end

function M.tryApplyMoneySubChange(diff)
    diff = math.abs(tonumber(diff) or 0)
    if diff == 0 then
        return
    end
    if state.originMoney - diff < 0 then
        return
    end
    local allowed = false
    allowed, state.moneyPtsNextAllowed = M.consumeDebounce(state.moneyPtsNextAllowed)
    if not allowed then
        return
    end
    data_ops.moneySubFunc(diff)
end

function M.tryApplyPointsChange(diff)
    diff = tonumber(diff)
    if diff == nil or diff <= 0 then
        return
    end
    if state.originPoints + diff > config.MONEY_PTS_MAX then
        return
    end
    local allowed = false
    allowed, state.moneyPtsNextAllowed = M.consumeDebounce(state.moneyPtsNextAllowed)
    if not allowed then
        return
    end
    data_ops.pointAddFunc(state.cBasicParam, diff)
end

function M.tryApplyPointsSubChange(diff)
    diff = math.abs(tonumber(diff) or 0)
    if diff == 0 then
        return
    end
    if state.originPoints - diff < 0 then
        return
    end
    local allowed = false
    allowed, state.moneyPtsNextAllowed = M.consumeDebounce(state.moneyPtsNextAllowed)
    if not allowed then
        return
    end
    data_ops.pointSubFunc(diff)
end

function M.renderCopyButton(label, content)
    local ok = true
    if imgui.button(label, config.LARGE_BTN) then
        ok = pcall(function()
            sdk.copy_to_clipboard(content)
        end)
    end
    if not ok then
        imgui.text_colored(state.i18n.reframeworkVersionError, config.ERROR_COLOR)
    end
end

function M.renderVersionInfo()
    if state.MAX_VER_LT_OR_EQ_GAME_VER == false then
        imgui.text_colored(state.i18n.compatibleWarning, config.ERROR_COLOR)
        imgui.text_colored(state.i18n.gameVersion .. state.GAME_VER .. " > " .. state.i18n.maxCompatibleVersion ..
                config.MAX_VERSION, config.ERROR_COLOR)
        imgui.new_line()
    end

    imgui.text_colored(state.i18n.backupSaveWarning, config.ERROR_COLOR)
    imgui.text(state.i18n.modVersion)
    imgui.same_line()
    imgui.text(config.INTER_VERSION)
    imgui.text(state.i18n.gameVersion)
    imgui.same_line()
    if state.MAX_VER_LT_OR_EQ_GAME_VER then
        imgui.text_colored(state.GAME_VER .. state.i18n.confirmCompatibleTip, config.CHECKED_COLOR)
    else
        imgui.text_colored(state.GAME_VER .. state.i18n.notCompatibleTip, config.ERROR_COLOR)
    end
    imgui.new_line()
end

return M
