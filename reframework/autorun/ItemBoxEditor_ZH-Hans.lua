-- Made By Egg Targaryen
-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For Monster Hunter: Wilds

-- !!! DO NOT MODIFY THE FOLLOWING CODE !!!
local ITEM_NAME_JSON_PATH = "ItemBoxEditor_item_dict_ZH-Hans.json"
local LANG = "ZH-Hans"
-- !!! DO NOT MODIFY THE ABOVE CODE !!!

-- Just change here can change every VERSION setting in all files
local INTER_VERSION = "v1.2"
local MAX_VERSION = "1.0.1.0"
-- Just change here can change every VERSION setting in all files END

local MONEY_PTS_MAX = 99999999
local ITEM_COUNT_MAX = 9999
local LARGE_BTN = Vector2f.new(300, 50)
local SMALL_BTN = Vector2f.new(200, 40)
local ERROR_COLOR = 0xeb4034ff
local CHECKED_COLOR = 0xff74ff33
local TIPS_COLOR = 0xff00c3ff
local GAME_VER = nil
local MAX_VER_LT_OR_EQ_GAME_VER = true
local FONT = nil

if LANG == "ZH-Hans" then
    local FONT_NAME = "NotoSansSC-Medium.ttf"
    local FONT_SIZE = 24
    local CHN_GLYPH = {
        0x0020, 0xFFEE,
        0,
    }
    FONT = imgui.load_font(FONT_NAME, FONT_SIZE, CHN_GLYPH)
end

-- NOT CHANGED VARIABLES:
local itemNameJson = nil
local i18n = nil
local addNewItemList = {}
local addNewItemNameList = {}
-- NOT CHANGED VARIABLES END

local boxItemArray = nil
local pouchItemArray = nil
local cItemParam = nil
local cBasicParam = nil


local existedItems = {}
local existedComboLabels = {}
local existedComboChanged = false
local existedSelectedIndex = nil
local existedSelectedItemFixedId = nil
local existedSelectedItemNum = nil
local existedSliderChanged = nil
local existedSliderNewVal = nil
local existedSearchedItems = {}
local existedComboSearchedLabels = {}
local existedSearchInputChanged = nil
local existedSearchInputNewVal = nil
local existedSearchInputVal = nil


local addNewItemComboChanged = false
local addNewItemComboSelectedIndex = nil
local addNewEmptyPouchItem = nil
local addNewInputChanged = nil
local addNewInputNewVal = nil
local addNewSliderChanged = nil
local addNewSliderNewVal = nil
local addNewItemId = nil
local addNewItemNum = nil
local addNewSearchedItems = nil
local addNewComboSearchedLabels = nil

local originMoney = 0
local moneySliderVal = 0
local moneyChangedDiff = 0
local originPoints = 0
local pointsSliderVal = 0
local pointsChangedDiff = 0
local moneySliderChanged = nil
local pointsSliderChange = nil
local moneySliderNewVal = nil
local pointsSliderNewVal = nil

local function clear()
    boxItemArray = nil
    cItemParam = nil
    cBasicParam = nil

    existedComboLabels = {}
    existedComboChanged = false
    existedSelectedIndex = nil
    existedSelectedItemFixedId = nil
    existedSelectedItemNum = nil
    existedSliderChanged = nil
    existedSliderNewVal = nil

    addNewItemComboChanged = false
    addNewItemComboSelectedIndex = nil
    addNewInputChanged = nil
    addNewInputNewVal = nil
    addNewSliderChanged = nil
    addNewSliderNewVal = nil
    addNewItemId = nil
    addNewItemNum = nil

    originMoney = 0
    moneySliderVal = 0
    moneyChangedDiff = 0
    originPoints = 0
    pointsSliderVal = 0
    pointsChangedDiff = 0
    moneySliderChanged = nil
    pointsSliderChange = nil
    moneySliderNewVal = nil
    pointsSliderNewVal = nil
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

local function checkItemName(input)
    if input:match("^%s*$") then
        return false
    end
    if input:match("Rejected") or input:match("%-%-%-") then
        return false
    end
    return true
end

local function loadI18NJson(jsonPath)
    print("Loading I18N JSON file: " .. jsonPath)
    if json ~= nil then
        local jsonFile = json.load_file(jsonPath)
        if jsonFile then
            i18n = jsonFile.I18N
            itemNameJson = jsonFile.ItemName
            local tempIndex = 1
            addNewItemList = {}
            for key, value in pairs(itemNameJson) do
                if checkItemName(value) then
                    addNewItemList[tempIndex] = {
                        name = "[" .. key .. "]" .. value .. " - 0",
                        fixedId = tonumber(key),
                        maxNum = ITEM_COUNT_MAX,
                    }
                    tempIndex = tempIndex + 1
                end
            end
            table.sort(addNewItemList, function(a, b)
                return a.fixedId < b.fixedId
            end)
            for itemIndex = 1, #addNewItemList do
                addNewItemNameList[itemIndex] = addNewItemList[itemIndex].name
            end
        end
    end
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
            local itemName = nil
            if itemNameJson[tostring(boxItem:get_field("ItemIdFixed"))] ~= nil then
                itemName = itemNameJson[tostring(boxItem:get_field("ItemIdFixed"))]
            else
                itemName = i18n.unknownItem
            end
            local comboxItem = "[" ..
                tostring(boxItem:get_field("ItemIdFixed")) .. "]" .. itemName .. " - " .. boxItem:get_field("Num")
            local itemInfo = {
                name = comboxItem,
                fixedId = boxItem:get_field("ItemIdFixed"),
                num = boxItem:get_field("Num")
            }
            for tempIndex = 1, #addNewItemList do
                if addNewItemList[tempIndex].fixedId == boxItem:get_field("ItemIdFixed") then
                    addNewItemList[tempIndex].name = comboxItem
                    addNewItemList[tempIndex].maxNum = ITEM_COUNT_MAX - tonumber(boxItem:get_field("Num"))
                    break
                end
            end
            existedItems[existedShowInComboxPosIndex] = itemInfo

            -- adjust the max item count in Item Add func
            -- addNewItemListMaxCount[tostring(boxItem:get_field("ItemIdFixed"))] = addNewItemListMaxCount
            --     [tostring(boxItem:get_field("ItemIdFixed"))] - tonumber(boxItem:get_field("Num"))

            existedShowInComboxPosIndex = existedShowInComboxPosIndex + 1
        end
    end
    table.sort(existedItems, function(a, b) return a.fixedId < b.fixedId end)
    for itemIndex = 0, #existedItems - 1 do
        existedComboLabels[itemIndex + 1] = existedItems[itemIndex + 1].name
    end
    for itemIndex = 0, #addNewItemList - 1 do
        addNewItemNameList[itemIndex + 1] = addNewItemList[itemIndex + 1].name
    end
    existedComboSearchedLabels = existedComboLabels
    existedSearchedItems = existedItems
    addNewComboSearchedLabels = addNewItemNameList
    addNewSearchedItems = addNewItemList
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
    moneySliderVal = originMoney
    pointsSliderVal = originPoints
end

local function changeBoxItemNum(itemFixedId, changedNumber)
    if changedNumber > 0 then
        for boxPosIndex = 0, #boxItemArray - 1 do
            if boxItemArray[boxPosIndex]:get_field("ItemIdFixed") == itemFixedId then
                local itemEnumId = boxItemArray[boxPosIndex]:call("get_ItemId")
                boxItemArray[boxPosIndex]:call("set", itemEnumId, changedNumber)
            end
        end
    else
        for boxPosIndex = 0, #boxItemArray - 1 do
            if boxItemArray[boxPosIndex]:get_field("ItemIdFixed") == itemFixedId then
                boxItemArray[boxPosIndex]:call("set_ItemId", 0)
                boxItemArray[boxPosIndex]:call("set", 0, 0)
            end
        end
    end
end

local function addNewToPouchItem(cItemWork, itemId, itemNum)
    itemId = tonumber(itemId) - 1
    if itemId > 0 and itemId <= 750 and itemNum > 0 then
        cItemWork:call("set_ItemId", itemId)
        cItemWork:call("set", itemId, itemNum)
    end
end

local function moneyAddFunc(cBasicData, newMoney)
    cBasicData:call("addMoney", newMoney, false)
end

local function pointAddFunc(cBasicData, newPoint)
    cBasicData:call("addPoint", newPoint, false)
end

local function filterCombo(array, searchStr)
    local filteredArray = {}
    local filteredArrayLabel = {}
    for index = 1, #array do
        if array[index].name:find(searchStr, 1, true) then
            table.insert(filteredArray, array[index])
            table.insert(filteredArrayLabel, array[index].name)
        end
    end
    return filteredArray, filteredArrayLabel
end


local function init()
    initBoxItem()
    initPouchItem()
    initHunterBasicData()

    existedSelectedItemFixedId = existedSearchedItems[1].fixedId
    existedSelectedItemNum = existedSearchedItems[1].num
end

loadI18NJson(ITEM_NAME_JSON_PATH)
getVersion()
MAX_VER_LT_OR_EQ_GAME_VER = compareVersions(GAME_VER, MAX_VERSION)

re.on_draw_ui(function()
    if FONT ~= nil then
        imgui.push_font(FONT)
    end
    imgui.begin_window(i18n.windowTitle, ImGuiWindowFlags_AlwaysAutoResize)

    if MAX_VER_LT_OR_EQ_GAME_VER == false then
        imgui.text_colored(i18n.compatibleWarning, ERROR_COLOR)
        imgui.text_colored(i18n.gameVersion .. GAME_VER .. " > " .. i18n.maxCompatibleVersion .. MAX_VERSION, ERROR_COLOR)
        imgui.new_line()
    end

    imgui.text_colored(i18n.backupSaveWarning, ERROR_COLOR)
    imgui.new_line()

    if imgui.button(i18n.readItemBoxBtn, LARGE_BTN) then
        init()
    end
    ------------------- existed item change -----------------
    imgui.new_line()
    imgui.text_colored(i18n.itemIdFileTip, TIPS_COLOR)
    imgui.text(i18n.changeItemNumTitle)
    imgui.begin_disabled(cItemParam == nil)
    existedSearchInputChanged, existedSearchInputNewVal = imgui.input_text(i18n.searchInput, existedSearchInputVal)
    if existedSearchInputChanged then
        existedSearchInputVal = existedSearchInputNewVal
        existedSelectedIndex = nil
        addNewItemComboSelectedIndex = nil
        if existedSearchInputNewVal == "" then
            existedComboSearchedLabels = existedComboLabels
            existedSearchedItems = existedItems
            addNewComboSearchedLabels = addNewItemNameList
            addNewSearchedItems = addNewItemList
        else
            existedSearchedItems, existedComboSearchedLabels = filterCombo(existedItems, existedSearchInputNewVal)
            addNewSearchedItems, addNewComboSearchedLabels = filterCombo(addNewItemList, existedSearchInputNewVal)
        end
    end
    existedComboChanged, existedSelectedIndex = imgui.combo(i18n.changeItemNumCombox, existedSelectedIndex,
        existedComboSearchedLabels)
    if existedComboChanged then
        existedSelectedItemFixedId = existedSearchedItems[existedSelectedIndex].fixedId
        existedSelectedItemNum = existedSearchedItems[existedSelectedIndex].num
    end
    existedSliderChanged, existedSliderNewVal = imgui.slider_int(i18n.changeItemNumSlider, existedSelectedItemNum, 1,
        9999)
    if existedSliderChanged then
        existedSelectedItemNum = existedSliderNewVal
    end
    if imgui.button(i18n.changeItemNumBtn, SMALL_BTN) then
        changeBoxItemNum(existedSelectedItemFixedId, existedSelectedItemNum)
        clear()
        init()
    end
    imgui.end_disabled()


    ------------------- add new item -----------------
    imgui.new_line()
    imgui.text(i18n.addItemToPouchTitle)
    imgui.begin_disabled(cItemParam == nil)
    imgui.text_colored(i18n.addItemToPouchComboxWarning, ERROR_COLOR)

    addNewItemComboChanged, addNewItemComboSelectedIndex = imgui.combo(
        i18n.addItemToPouchCombox,
        addNewItemComboSelectedIndex,
        addNewComboSearchedLabels)
    if addNewItemComboChanged then
        addNewItemId = addNewSearchedItems[addNewItemComboSelectedIndex].fixedId
    end
    addNewInputChanged, addNewInputNewVal, start = imgui.input_text(i18n.addItemToPouchInput, addNewItemId)
    if addNewInputChanged then
        addNewItemId = addNewInputNewVal
    end
    local textSlider
    if addNewItemComboSelectedIndex == nil then
        textSlider = "9999"
    else
        textSlider = tostring(addNewSearchedItems[addNewItemComboSelectedIndex].maxNum)
    end
    addNewSliderChanged, addNewSliderNewVal = imgui.slider_int(
        i18n.addItemToPouchSlider .. textSlider,
        addNewItemNum, 1, tonumber(textSlider))
    if addNewSliderChanged then
        addNewItemNum = addNewSliderNewVal
    end
    imgui.text(i18n.addItemToPouchWarning)
    if imgui.button(i18n.addItemToPouchBtn, SMALL_BTN) then
        addNewToPouchItem(addNewEmptyPouchItem, addNewItemId, addNewItemNum)
        clear()
        init()
    end
    imgui.end_disabled()



    ------------------- user data change -----------------
    imgui.new_line()
    imgui.text(i18n.coinAndPtsEditorTitle)
    imgui.begin_disabled(cBasicParam == nil)
    moneySliderChanged, moneySliderNewVal = imgui.slider_int(
        i18n.coinSlider .. " (" .. originMoney .. "~" .. (MONEY_PTS_MAX - originMoney) .. ")", moneySliderVal,
        originMoney,
        MONEY_PTS_MAX - originMoney)
    if moneySliderChanged then
        moneyChangedDiff = moneySliderNewVal - originMoney
        moneySliderVal = moneySliderNewVal
    end
    if imgui.button(i18n.coinBtn, SMALL_BTN) then
        moneyAddFunc(cBasicParam, moneyChangedDiff)
        clear()
        init()
    end
    pointsSliderChange, pointsSliderNewVal = imgui.slider_int(
        i18n.ptsSlider .. " (" .. originPoints .. "~" .. (MONEY_PTS_MAX - originPoints) .. ")", pointsSliderVal,
        originPoints,
        MONEY_PTS_MAX - originPoints)
    if pointsSliderChange then
        pointsChangedDiff = pointsSliderNewVal - originPoints
        pointsSliderVal = pointsSliderNewVal
    end
    if imgui.button(i18n.ptsBtn, SMALL_BTN) then
        pointAddFunc(cBasicParam, pointsChangedDiff)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text(i18n.modVersion)
    imgui.same_line()
    imgui.text(INTER_VERSION)
    imgui.text(i18n.gameVersion)
    imgui.same_line()
    if MAX_VER_LT_OR_EQ_GAME_VER then
        imgui.text_colored(GAME_VER .. i18n.confirmCompatibleTip, CHECKED_COLOR)
    else
        imgui.text_colored(GAME_VER .. i18n.notCompatibleTip, ERROR_COLOR)
    end

    imgui.end_window()
end)
