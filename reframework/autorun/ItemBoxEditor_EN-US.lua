-- Made By Egg Targaryen
-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For Monster Hunter: Wilds
local INTER_VERSION = "v0.8"
local MAX_VERSION = "1.0.1.0"
local I18N = {
    windowTitle = "ItemBox Editor",
    compatibleWarning = "[Warning] Your game version is NOT compatible with this mod: ",
    gameVersion = "Game Version",
    modVersion = "MOD Version",
    maxCompatibleVersion = "MOD Compatible Version",
    confirmCompatibleTip = "[Compatible]",
    notCompatibleTip = "[NOT Compatible]",
    backupSaveWarning = "[Warning] Please backup your save before using this mod !!!",
    readItemBoxBtn = "Read In-Game ItemBox",
    changeItemNumTitle = "Item Count Changer:",
    changeItemNumCombox = "Change Existed Item Number",
    changeItemNumSlider = "Select Add Num (1~9999)",
    changeItemNumBtn = "Confirm Change",
    addItemToPouchTitle = "Item Count Add:",
    addItemToPouchCombox = "Enter the Item ID",
    addItemToPouchSlider = "Select Add Num (1~9999)",
    addItemToPouchBtn = "Confirm Add",
    addItemToPouchWarning =
    "Added items will appear in your POUCH, please use the in-game organizing to automatically send the items to the box",
    coinAndPtsEditorTitle = "Money & Points Add:",
    coinSlider = "Select New Money",
    coinBtn = "Confirm Money Edit",
    ptsSlider = "Select New Points",
    ptsBtn = "Confirm Points Edit",
}
local MONEY_PTS_MAX = 99999999
local LARGE_BTN = Vector2f.new(300, 50)
local SMALL_BTN = Vector2f.new(200, 40)
local ERROR_COLOR = 0xeb4034ff
local CHECKED_COLOR = 0xff74ff33
local GAME_VER = nil
local MAX_VER_LT_OR_EQ_GAME_VER = true
local FONT_NAME = "NotoSansSC-Medium.ttf"
local FONT_SIZE = 24
local CHN_GLYPH = {
    0x0020, 0xFFEE,
    0,
}
local FONT = imgui.load_font(FONT_NAME, FONT_SIZE, CHN_GLYPH)

local boxItemArray = nil
local pouchItemArray = nil
local cItemParam = nil
local cBasicParam = nil

local existedComboLabels = {}
local existedComboItemIdFixedValues = {}
local existedComboItemNumValues = {}
local existedComboChanged = false
local existedSelectedIndex = nil
local existedSelectedItemFixedId = nil
local existedSelectedItemNum = nil
local existedSliderChanged = nil
local existedSliderNewVal = nil

local addNewEmptyPouchItem = nil
local addNewInputChanged = nil
local addNewInputNewVal = nil
local addNewSliderChanged = nil
local addNewSliderNewVal = nil
local addNewItemId = nil
local addNewItemNum = nil

local originMoney = 0
local moneySilderVal = 0
local moneyChangedDiff = 0
local originPoints = 0
local pointsSilderVal = 0
local pointsChangedDiff = 0
local moneySilderChanged = nil
local pointsSilderChange = nil
local moneySilderNewVal = nil
local pointsSilderNewVal = nil

local function clear()
    boxItemArray = nil
    cItemParam = nil
    cBasicParam = nil

    existedComboLabels = {}
    existedComboItemIdFixedValues = {}
    existedComboItemNumValues = {}
    existedComboChanged = false
    existedSelectedIndex = nil
    existedSelectedItemFixedId = nil
    existedSelectedItemNum = nil
    existedSliderChanged = nil
    existedSliderNewVal = nil

    addNewInputChanged = nil
    addNewInputNewVal = nil
    addNewSliderChanged = nil
    addNewSliderNewVal = nil
    addNewItemId = nil
    addNewItemNum = nil

    originMoney = 0
    moneySilderVal = 0
    moneyChangedDiff = 0
    originPoints = 0
    pointsSilderVal = 0
    pointsChangedDiff = 0
    moneySilderChanged = nil
    pointsSilderChange = nil
    moneySilderNewVal = nil
    pointsSilderNewVal = nil
end

local function getVersion()
    local sysService = sdk.get_native_singleton("via.SystemService")
    local sysServiceType = sdk.find_type_definition("via.SystemService")
    GAME_VER = sdk.call_native_func(sysService, sysServiceType, "get_ApplicationVersion"):match("Product:([^,]+)")
end

function compareVersions(version1, version2)
    local v1Parts = {}
    for num in version1:gmatch("%d+") do
        table.insert(v1Parts, tonumber(num))
    end
    local v2Parts = {}
    for num in version2:gmatch("%d+") do
        table.insert(v2Parts, tonumber(num))
    end
    for i = 1, 4 do
        if v1Parts[i] > v2Parts[i] then
            return false
        elseif v1Parts[i] < v2Parts[i] then
            return true
        end
    end
    return true
end

function getUIName(guid)
    local uiName = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid)"):call(nil, guid)
    if not uiName then
        return tostring(guid)
    else
        return tostring(uiName)
    end
end

function getItemGuid(itemIdFixed)
    local cData = sdk.find_type_definition("app.ItemDef"):get_method("getDataByDataIndex(System.Int32)"):call(nil, itemFixedId)
    return cData:get_field("_RawName")
end

local function initBoxItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    cItemParam = cUserSaveParam:get_field("_Item")
    boxItemArray = cItemParam:call("get_BoxItem")
    local existedShowInComboxPosIndex = 1
    for boxPosIndex = 0, #boxItemArray - 1 do
        local boxItem = boxItemArray[boxPosIndex]
        if boxItem:get_field("Num") > 0 then
            -- print(boxItem:call("get_ItemId"))
            -- local comboxItem = I18N.itemName .. " " .. getUIName(getItemGuid(boxItem:get_field("ItemIdFixed"))) .. " - " .. I18N.itemCount .. " " .. boxItem:get_field("Num")
            local comboxItem = I18N.itemName .. " " .. boxItem:get_field("ItemIdFixed") .. " - " .. I18N.itemCount .. " " .. boxItem:get_field("Num")
            existedComboLabels[existedShowInComboxPosIndex] = comboxItem
            existedComboItemIdFixedValues[existedShowInComboxPosIndex] = boxItem:get_field("ItemIdFixed")
            existedComboItemNumValues[existedShowInComboxPosIndex] = boxItem:get_field("Num")
            existedShowInComboxPosIndex = existedShowInComboxPosIndex + 1
        end
    end
end

local function initPouchItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    cItemParam = cUserSaveParam:get_field("_Item")
    pouchItemArray = cItemParam:call("get_PouchItem")
    for pouchItemIndex = 0, #pouchItemArray - 1 do
        if pouchItemArray[pouchItemIndex]:get_field("Num") == 0 then
            addNewEmptyPouchItem = pouchItemArray[pouchItemIndex]
            break
        end
    end
end

local function initHunterBasicData()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    cBasicParam = cUserSaveParam:get_field("_BasicData")
    originMoney = cBasicParam:call("getMoney")
    originPoints = cBasicParam:call("getPoint")
    moneySilderVal = originMoney
    pointsSilderVal = originPoints
end

local function changeBoxItemNum(itemFixedId, changedNumber)
    if changedNumber >= 0 then
        for boxPosIndex = 0, #boxItemArray - 1 do
            if boxItemArray[boxPosIndex]:get_field("ItemIdFixed") == itemFixedId then
                local itemEnumId = boxItemArray[boxPosIndex]:call("get_ItemId")
                boxItemArray[boxPosIndex]:call("set", itemEnumId, changedNumber)
                cItemParam:call("adjustItemOrder", itemEnumId, boxItemArray)
                print("Changed ID: " .. itemEnumId)
            end
        end
    end
end

local function addNewToPouchItem(cItemWork, itemId, itemNum)
    itemId = tonumber(itemId) - 1
    if itemId > 0 and itemId <= 750 and itemNum > 0 then
        cItemWork:call("set_ItemId", itemId)
        cItemWork:call("set", itemId, itemNum)
        print("Changed ID: " .. cItemWork:call("get_ItemId"))
    end
end

local function moneyAddFunc(cBasicData, newMoney)
    cBasicData:call("addMoney", newMoney, false)
end

local function pointAddFunc(cBasicData, newPoint)
    cBasicData:call("addPoint", newPoint, false)
end

local function init()
    initBoxItem()
    initPouchItem()
    initHunterBasicData()

    existedSelectedItemFixedId = existedComboItemIdFixedValues[1]
    existedSelectedItemNum = existedComboItemNumValues[1]
end

re.on_draw_ui(function()
    imgui.push_font(FONT)
    imgui.begin_window(I18N.windowTitle, ImGuiWindowFlags_AlwaysAutoResize)
    getVersion()
    MAX_VER_LT_OR_EQ_GAME_VER = compareVersions(GAME_VER, MAX_VERSION)

    if MAX_VER_LT_OR_EQ_GAME_VER == false then
        imgui.text_colored(I18N.compatibleWarning, ERROR_COLOR)
        imgui.text_colored(I18N.gameVersion .. GAME_VER .. " > " .. I18N.maxCompatibleVersion .. MAX_VERSION, ERROR_COLOR)
        imgui.new_line()
    end

    imgui.text_colored(I18N.backupSaveWarning, ERROR_COLOR)

    if imgui.button(I18N.readItemBoxBtn, LARGE_BTN) then
        init()
    end

    imgui.new_line()
    imgui.text(I18N.changeItemNumTitle)
    imgui.begin_disabled(cItemParam == nil)
    existedComboChanged, existedSelectedIndex = imgui.combo(I18N.changeItemNumCombox, existedSelectedIndex,
        existedComboLabels)
    if existedComboChanged then
        existedSelectedItemFixedId = existedComboItemIdFixedValues[existedSelectedIndex]
        existedSelectedItemNum = existedComboItemNumValues[existedSelectedIndex]
    end
    existedSliderChanged, existedSliderNewVal = imgui.slider_int(I18N.changeItemNumSlider, existedSelectedItemNum, 1,
        9999)
    if existedSliderChanged then
        existedSelectedItemNum = existedSliderNewVal
    end
    if imgui.button(I18N.changeItemNumBtn, SMALL_BTN) then
        changeBoxItemNum(existedSelectedItemFixedId, existedSelectedItemNum)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text(I18N.addItemToPouchTitle)
    imgui.begin_disabled(cItemParam == nil)
    addNewInputChanged, addNewInputNewVal, start = imgui.input_text(I18N.addItemToPouchCombox, addNewItemId)
    if addNewInputChanged then
        addNewItemId = addNewInputNewVal
    end
    addNewSliderChanged, addNewSliderNewVal = imgui.slider_int(I18N.addItemToPouchSlider, addNewItemNum, 1, 9999)
    if addNewSliderChanged then
        addNewItemNum = addNewSliderNewVal
    end
    imgui.text(I18N.addItemToPouchWarning)
    if imgui.button(I18N.addItemToPouchBtn, SMALL_BTN) then
        addNewToPouchItem(addNewEmptyPouchItem, addNewItemId, addNewItemNum)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text(I18N.coinAndPtsEditorTitle)
    imgui.begin_disabled(cBasicParam == nil)
    moneySilderChanged, moneySilderNewVal = imgui.slider_int(
        I18N.coinSlider .. " (" .. originMoney .. "~" .. (MONEY_PTS_MAX - originMoney) .. ")", moneySilderVal, originMoney,
        MONEY_PTS_MAX - originMoney)
    if moneySilderChanged then
        moneyChangedDiff = moneySilderNewVal - originMoney
        moneySilderVal = moneySilderNewVal
    end
    if imgui.button(I18N.coinBtn, SMALL_BTN) then
        moneyAddFunc(cBasicParam, moneyChangedDiff)
        clear()
        init()
    end
    pointsSilderChange, pointsSilderNewVal = imgui.slider_int(
        I18N.ptsSlider .. " (" .. originPoints .. "~" .. (MONEY_PTS_MAX - originPoints) .. ")", pointsSilderVal,
        originPoints,
        MONEY_PTS_MAX - originPoints)
    if pointsSilderChange then
        pointsChangedDiff = pointsSilderNewVal - originPoints
        pointsSilderVal = pointsSilderNewVal
    end
    if imgui.button(I18N.ptsBtn, SMALL_BTN) then
        pointAddFunc(cBasicParam, pointsChangedDiff)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text(I18N.modVersion)
    imgui.same_line()
    imgui.text(INTER_VERSION)
    imgui.text(I18N.gameVersion)
    imgui.same_line()
    if MAX_VER_LT_OR_EQ_GAME_VER then
        imgui.text_colored(GAME_VER .. I18N.confirmCompatibleTip, CHECKED_COLOR)
    else
        imgui.text_colored(GAME_VER .. I18N.notCompatibleTip, ERROR_COLOR)
    end

    imgui.end_window()
end)
