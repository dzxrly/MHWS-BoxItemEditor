local M = {}

-- NOT CHANGED VARIABLES:
M.itemNameJson = nil
M.i18n = nil
-- NOT CHANGED VARIABLES END

-- === Runtime state ===
-- window status
M.isLoadLanguage = false
M.userConfig = {
    mainWindowOpen = false,
    itemWindowOpen = false,
    aboutWindowOpen = false,
    userLanguage = "en-US"
}
M.mainWindowState = M.userConfig.mainWindowOpen
M.itemWindowState = M.userConfig.itemWindowOpen
M.aboutWindowState = M.userConfig.aboutWindowOpen
M.userLanguage = "en-US" -- default language
-- window status end

-- item table window
M.searchItemTarget = nil
M.searchItemResult = {}
-- item table window end
M.itemBoxList = {}
M.itemIDAndFixedIDProjection = {} -- fixedId -> itemId
M.boxItemArray = nil
M.cItemParam = nil
M.cBasicParam = nil

M.itemBoxComboChanged = false
M.itemBoxComboIndex = 1
M.itemBoxSelectedItemFixedId = nil
M.itemBoxSelectedItemNum = nil
M.itemBoxSliderChanged = nil
M.itemBoxSliderNewVal = nil
M.itemBoxSearchedItems = {}
M.itemBoxSearchedLabels = {}
M.itemBoxInputChanged = nil
M.itemBoxInputCountChanged = nil
M.itemBoxInputCountNewVal = nil
M.itemBoxConfirmBtnEnabled = true

M.rareFilterComboChanged = nil
M.typeFilterComboChanged = nil
M.filterSetting = {
    searchStr = "",
    filterIndex = 1,
    rareIndex = 1
}
M.typeFilterLabel = {}
M.rareFilterLabel = {}

M.originMoney = 0
M.originPoints = 0
M.moneyPtsNextAllowed = 0
M.moneySliderVal = 0
M.moneySliderChanged = false
M.moneyInputVal = "0"
M.moneyInputChanged = nil
M.moneyInputValid = true
M.ptsSliderVal = 0
M.ptsSliderChanged = false
M.ptsInputVal = "0"
M.ptsInputChanged = nil
M.ptsInputValid = true

M.newHunterName = ""
M.newOtomoName = ""
M.hunterNameInputChanged = nil
M.hunterNameResetBtnEnabled = false
M.otomoNameInputChanged = nil
M.otomoNameResetBtnEnabled = false

M.isInitError = false
M.initErrorMsg = ""

M.GAME_VER = nil
M.MAX_VER_LT_OR_EQ_GAME_VER = true

function M.clear()
    -- item box state
    M.boxItemArray = nil
    M.cItemParam = nil
    M.cBasicParam = nil

    M.itemBoxComboChanged = false
    M.itemBoxComboIndex = 1
    M.itemBoxSelectedItemFixedId = nil
    M.itemBoxSelectedItemNum = nil
    M.itemBoxSliderChanged = nil
    M.itemBoxSliderNewVal = nil
    M.itemBoxInputChanged = nil
    M.itemBoxInputCountChanged = nil
    M.itemBoxInputCountNewVal = nil
    M.itemBoxConfirmBtnEnabled = true

    -- money/points state
    M.originMoney = 0
    M.originPoints = 0
    M.moneyPtsNextAllowed = 0
    M.moneySliderVal = 0
    M.moneySliderChanged = false
    M.moneyInputVal = "0"
    M.moneyInputChanged = nil
    M.moneyInputValid = true
    M.ptsSliderVal = 0
    M.ptsSliderChanged = false
    M.ptsInputVal = "0"
    M.ptsInputChanged = nil
    M.ptsInputValid = true

    -- name reset state
    M.newHunterName = ""
    M.newOtomoName = ""
    M.hunterNameInputChanged = nil
    M.hunterNameResetBtnEnabled = false
    M.otomoNameInputChanged = nil
    M.otomoNameResetBtnEnabled = false
end

return M
