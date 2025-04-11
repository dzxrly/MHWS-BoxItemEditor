-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For Monster Hunter: Wilds

-- !!! DO NOT MODIFY THE FOLLOWING CODE !!!
local ITEM_NAME_JSON_PATH = ""
local USER_CONFIG_PATH = ""
local LANG = ""
local FONT_NAME = ""
local FONT_SIZE = 24
local FONT_GLYPH = {
    0x0020, 0xFFEE,
    0,
}
local ITEM_ID_MAX = 824
-- !!! DO NOT MODIFY THE ABOVE CODE !!!

-- Just change here can change every VERSION setting in all files
local INTER_VERSION = "v1.8.2"
local MAX_VERSION = "1.1.0.0"
-- Just change here can change every VERSION setting in all files END

local MONEY_PTS_MAX = 99999999
local ADD_1E4 = 10000
local ADD_5E4 = 50000
local ADD_1E5 = 100000
local LARGE_BTN = Vector2f.new(300, 50)
local SMALL_BTN = Vector2f.new(200, 40)
local WINDOW_WIDTH_M = 300
local WINDOW_WIDTH_S = 150
local ERROR_COLOR = 0xeb4034ff
local CHECKED_COLOR = 0xff74ff33
local TIPS_COLOR = 0xff00c3ff
local GAME_VER = nil
local MAX_VER_LT_OR_EQ_GAME_VER = true
local FONT = nil

if LANG ~= "EN-US" then
    FONT = imgui.load_font(FONT_NAME, FONT_SIZE, FONT_GLYPH)
end

-- NOT CHANGED VARIABLES:
local itemNameJson = nil
local i18n = nil
-- NOT CHANGED VARIABLES END

-- window status
local userConfig = {
    mainWindowOpen = false,
    itemWindowOpen = false,
    aboutWindowOpen = false
}
local mainWindowState = userConfig.mainWindowOpen
local itemWindowState = userConfig.itemWindowOpen
local aboutWindowState = userConfig.aboutWindowOpen
-- window status end

-- item table window
local searchItemTarget = nil
local searchItemResult = {}
-- item table window end
local itemBoxList = {}
local itemIDAndFixedIDProjection = {} -- fixedId -> itemId
local boxItemArray = nil
local cItemParam = nil
local cBasicParam = nil

local itemBoxLabels = {}
local itemBoxComboChanged = false
local itemBoxComboIndex = 1
local itemBoxSelectedItemFixedId = nil
local itemBoxSelectedItemNum = nil
local itemBoxSliderChanged = nil
local itemBoxSliderNewVal = nil
local itemBoxSearchedItems = {}
local itemBoxSearchedLabels = {}
local itemBoxInputChanged = nil
local itemBoxInputNewVal = nil
local itemBoxInputVal = nil
local itemBoxInputCountChanged = nil
local itemBoxInputCountNewVal = nil
local itemBoxConfirmBtnEnabled = true

local rareFilterComboChanged = nil
local typeFilterComboChanged = nil
local filterSetting = { searchStr = "", filterIndex = 1, rareIndex = 1 }
local typeFilterLabel = {}
local rareFilterLabel = {}

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

    itemBoxLabels = {}
    itemBoxComboChanged = false
    itemBoxComboIndex = 1
    itemBoxSelectedItemFixedId = nil
    itemBoxSelectedItemNum = nil
    itemBoxSliderChanged = nil
    itemBoxSliderNewVal = nil
    itemBoxInputChanged = nil
    itemBoxInputNewVal = nil
    itemBoxInputVal = nil
    itemBoxInputCountChanged = nil
    itemBoxInputCountNewVal = nil
    itemBoxConfirmBtnEnabled = true

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
    GAME_VER = sdk.call_native_func(sysService, sysServiceType, "get_ApplicationVersion()"):match("Product:([^,]+)")
end

local function compareVersions(version1, version2)
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

local function checkItem(input)
    if input["_OutBox"] then
        return false
    end
    return true
end

local function checkIntegerInRange(input_str, min_val, max_val)
    local num = tonumber(input_str)
    if num and num == math.floor(num) and num >= min_val and num <= max_val then
        return num
    end
    return nil
end

local function initIDAndFixedIDProjection()
    local getFixedFromID = sdk.find_type_definition("app.ItemDef"):get_method("ItemId(app.ItemDef.ID)")
    for index = 1, ITEM_ID_MAX do
        local fixedID = getFixedFromID(nil, index)
        if fixedID ~= nil then
            itemIDAndFixedIDProjection[fixedID] = index
        end
    end
end

local function loadUserConfigJson(jsonPath)
    if json ~= nil then
        local jsonFile = json.load_file(jsonPath)
        if jsonFile then
            userConfig.mainWindowOpen = jsonFile.mainWindowOpen
            userConfig.itemWindowOpen = jsonFile.itemWindowOpen
            userConfig.aboutWindowOpen = jsonFile.aboutWindowOpen
            mainWindowState = userConfig.mainWindowOpen
            itemWindowState = userConfig.itemWindowOpen
            aboutWindowState = userConfig.aboutWindowOpen
        else
            json.dump_file(jsonPath, userConfig)
        end
    end
end

local function saveUserConfigJson(jsonPath)
    if json ~= nil then
        json.dump_file(jsonPath, userConfig)
    end
end

local function loadI18NJson(jsonPath)
    print("Loading I18N JSON file: " .. jsonPath)
    if json ~= nil then
        local jsonFile = json.load_file(jsonPath)
        if jsonFile then
            i18n = jsonFile.I18N
            itemNameJson = jsonFile.ItemName
            local tempIndex = 1
            itemBoxList = {}
            print(itemNameJson[1]["_Name"])
            for index = 1, #itemNameJson do
                if checkItem(itemNameJson[index]) then
                    itemBoxList[tempIndex] = itemNameJson[index]
                    itemBoxList[tempIndex]["name"] = "[" ..
                        itemNameJson[index]["fixedId"] .. "]" .. itemNameJson[index]["_Name"] .. " - 0"
                    itemBoxList[tempIndex]["num"] = 0
                    itemBoxList[tempIndex]["isUnknown"] = false
                    itemBoxList[tempIndex]["id"] = itemIDAndFixedIDProjection[itemNameJson[index]["fixedId"]]
                    print("Fixed ID: " .. itemBoxList[tempIndex]["fixedId"] .. " ID: " .. itemBoxList[tempIndex]["id"])
                    tempIndex = tempIndex + 1
                end
            end
            table.sort(itemBoxList, function(a, b)
                return a._SortId < b._SortId
            end)
        end
    end
    typeFilterLabel = i18n.typeFilterComboLabel
    table.insert(typeFilterLabel, 1, i18n.filterNoLimitTitle)
    rareFilterLabel = { "1", "2", "3", "4", "5", "6", "7", "8" }
    table.insert(rareFilterLabel, 1, i18n.filterNoLimitTitle)
end

local function searchItemList(target)
    local itemIndex = 0
    local itemMap = {}
    for index = 1, #itemNameJson do
        if checkItem(itemNameJson[index]) then
            if target ~= nil then
                if string.lower(itemNameJson[index]._Name):match(string.lower(target)) then
                    itemMap[itemIndex] = {
                        key = tonumber(itemNameJson[index].fixedId),
                        value = itemNameJson[index]
                            ._Name
                    }
                    itemIndex = itemIndex + 1
                end
            else
                itemMap[itemIndex] = { key = tonumber(itemNameJson[index].fixedId), value = itemNameJson[index]._Name }
                itemIndex = itemIndex + 1
            end
        end
    end

    table.sort(itemMap, function(a, b)
        return a.key < b.key
    end)

    return itemMap
end

local function filterCombo(array, filterSetting)
    local filteredArray = {}
    local filteredArrayLabel = {}
    local category = { _Type = nil, _Heal = false, _Battle = false, _OutBox = false }
    local tempArray = {}
    local switch = {
        -- { "无筛选条件", "治疗道具", "战斗道具", "调和素材", "制造材料", "弩炮弹药", "特产", "换金素材" }
        function()
            return
        end,
        function()
            category._Type = 0
            category._Heal = true
        end,
        function()
            category._Type = 0
            category._Battle = true
        end,
        function()
            category._Type = 0
        end,
        function()
            category._Type = 2
        end,
        function()
            category._Type = 3
        end,
        function()
            category._Type = 5
        end,
        function()
            category._Type = 2
            category._ForMoney = true
        end
    }
    switch[filterSetting.filterIndex]()
    if category._Type ~= nil then
        tempArray = {}
        for index = 1, #array do
            local isMatched = true
            for key, value in pairs(category) do
                if array[index][key] ~= value then
                    isMatched = false
                end
            end
            if isMatched then
                table.insert(tempArray, array[index])
            end
        end
        array = tempArray
    end

    if filterSetting.rareIndex > 1 then
        tempArray = {}
        local rare = 20 - filterSetting.rareIndex
        for index = 1, #array do
            if array[index]._Rare == rare then
                table.insert(tempArray, array[index])
            end
        end
        array = tempArray
    end

    for index = 1, #array do
        if filterSetting.searchStr == "" or array[index].name:find(filterSetting.searchStr, 1, true) then
            table.insert(filteredArray, array[index])
            table.insert(filteredArrayLabel, array[index].name)
        end
    end
    return filteredArray, filteredArrayLabel
end

local function initBoxItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData()")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    cItemParam = cUserSaveParam:get_field("_Item")
    boxItemArray = cItemParam:call("get_BoxItem()")
    for boxPosIndex = 0, #boxItemArray - 1 do
        local boxItem = boxItemArray[boxPosIndex]
        local isNotInList = true
        if boxItem:get_field("Num") > 0 then
            local itemName = nil

            for index = 1, #itemNameJson do
                if itemNameJson[index].fixedId == boxItem:get_field("ItemIdFixed") then
                    isNotInList = false
                    itemName = itemNameJson[index]._Name
                end
            end

            if isNotInList then
                itemName = i18n.unknownItem
                local itemInfo = {
                    name = "[" ..
                        tostring(boxItem:get_field("ItemIdFixed")) ..
                        "]" .. itemName .. " - " .. boxItem:get_field("Num"),
                    fixedId = boxItem:get_field("ItemIdFixed"),
                    num = boxItem:get_field("Num"),
                    _SortId = 99999,
                    isUnknown = true
                }
                table.insert(itemBoxList, itemInfo)
            else
                for tempIndex = 1, #itemBoxList do
                    if itemBoxList[tempIndex].fixedId == boxItem:get_field("ItemIdFixed") then
                        itemBoxList[tempIndex].name = "[" ..
                            tostring(boxItem:get_field("ItemIdFixed")) ..
                            "]" .. itemName .. " - " .. boxItem:get_field("Num")
                        itemBoxList[tempIndex].num = boxItem:get_field("Num")
                        break
                    end
                end
            end
        end
    end
    table.sort(itemBoxList, function(a, b)
        return a._SortId < b._SortId
    end)
    for itemIndex = 1, #itemBoxList do
        itemBoxLabels[itemIndex] = itemBoxList[itemIndex].name
    end
    itemBoxSearchedItems, itemBoxSearchedLabels = filterCombo(itemBoxList, filterSetting)
    itemBoxSelectedItemFixedId = itemBoxSearchedItems[itemBoxComboIndex].fixedId
    itemBoxSelectedItemNum = itemBoxSearchedItems[itemBoxComboIndex].num
    itemBoxInputCountNewVal = tostring(itemBoxSelectedItemNum)
end

local function initHunterBasicData()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData()")
    cBasicParam = cUserSaveParam:get_field("_BasicData")
    originMoney = cBasicParam:call("getMoney()")
    originPoints = cBasicParam:call("getPoint()")
    moneySliderVal = originMoney
    pointsSliderVal = originPoints
end

local function changeBoxItemNum(itemFixedId, changedNumber)
    local itemID = itemIDAndFixedIDProjection[itemFixedId]
    local boxItem = cItemParam:call("getBoxItem(app.ItemDef.ID)", itemID)
    if boxItem == nil then
        cItemParam:call("changeItemBoxNum(app.ItemDef.ID, System.Int16)", itemID, changedNumber)
    else
        cItemParam:call("changeItemBoxNum(app.ItemDef.ID, System.Int16)", itemID,
            changedNumber - boxItem:get_field("Num"))
    end
    if changedNumber == 0 then
        for index = 1, #itemBoxList do
            if itemBoxList[index].fixedId == itemFixedId then
                itemBoxList[index]["name"] = "[" ..
                    itemBoxList[index]["fixedId"] .. "]" .. itemBoxList[index]["_Name"] .. " - 0"
                itemBoxList[index]["num"] = 0
            end
        end
    end
end

local function moneyAddFunc(cBasicData, newMoney)
    cBasicData:call("addMoney(System.Int32, System.Boolean)", newMoney, false)
end

local function pointAddFunc(cBasicData, newPoint)
    cBasicData:call("addPoint(System.Int32, System.Boolean)", newPoint, false)
end

local function init()
    initBoxItem()
    initHunterBasicData()
end

local function mainWindow()
    if imgui.begin_window(i18n.windowTitle, mainWindowState, ImGuiWindowFlags_AlwaysAutoResize) then
        if MAX_VER_LT_OR_EQ_GAME_VER == false then
            imgui.text_colored(i18n.compatibleWarning, ERROR_COLOR)
            imgui.text_colored(i18n.gameVersion .. GAME_VER .. " > " .. i18n.maxCompatibleVersion .. MAX_VERSION,
                ERROR_COLOR)
            imgui.new_line()
        end

        imgui.text_colored(i18n.backupSaveWarning, ERROR_COLOR)
        imgui.new_line()

        if imgui.button(i18n.readItemBoxBtn, LARGE_BTN) then
            init()
        end
        ------------------- existed item change -----------------
        imgui.begin_disabled(cItemParam == nil)
        imgui.new_line()
        imgui.text_colored(i18n.itemIdFileTip, TIPS_COLOR)
        imgui.text(i18n.changeItemNumTitle)
        imgui.set_next_item_width(WINDOW_WIDTH_S)
        typeFilterComboChanged, filterSetting.filterIndex = imgui.combo(i18n.changeItemNumFilterItemType,
            filterSetting.filterIndex, typeFilterLabel);
        imgui.same_line()
        imgui.set_next_item_width(WINDOW_WIDTH_S)
        rareFilterComboChanged, filterSetting.rareIndex = imgui.combo(i18n.changeItemNumFilterItemRare,
            filterSetting.rareIndex, rareFilterLabel)
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        itemBoxInputChanged, filterSetting.searchStr = imgui.input_text(i18n.searchInput, filterSetting.searchStr)

        if rareFilterComboChanged then
            itemBoxComboIndex = 1
            itemBoxSearchedItems, itemBoxSearchedLabels = filterCombo(itemBoxList, filterSetting)
            if #itemBoxSearchedItems > 0 then
                itemBoxSelectedItemFixedId = itemBoxSearchedItems[1].fixedId
                itemBoxSelectedItemNum = itemBoxSearchedItems[1].num
            end
        end

        if typeFilterComboChanged then
            itemBoxComboIndex = 1
            itemBoxSearchedItems, itemBoxSearchedLabels = filterCombo(itemBoxList, filterSetting)
            if #itemBoxSearchedItems > 0 then
                itemBoxSelectedItemFixedId = itemBoxSearchedItems[1].fixedId
                itemBoxSelectedItemNum = itemBoxSearchedItems[1].num
            end
        end

        if itemBoxInputChanged then
            itemBoxComboIndex = 1
            itemBoxSearchedItems, itemBoxSearchedLabels = filterCombo(itemBoxList, filterSetting)
            if #itemBoxSearchedItems > 0 then
                itemBoxSelectedItemFixedId = itemBoxSearchedItems[1].fixedId
                itemBoxSelectedItemNum = itemBoxSearchedItems[1].num
            end
        end

        imgui.set_next_item_width(WINDOW_WIDTH_M)
        itemBoxComboChanged, itemBoxComboIndex = imgui.combo(i18n.changeItemNumCombox, itemBoxComboIndex,
            itemBoxSearchedLabels)
        if itemBoxComboChanged then
            itemBoxSelectedItemFixedId = itemBoxSearchedItems[itemBoxComboIndex].fixedId
            itemBoxSelectedItemNum = itemBoxSearchedItems[itemBoxComboIndex].num
            itemBoxInputCountNewVal = tostring(itemBoxSelectedItemNum)
        end
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        itemBoxSliderChanged, itemBoxSliderNewVal = imgui.slider_int(i18n.changeItemNumSlider, itemBoxSelectedItemNum, 0,
            9999)
        if itemBoxSliderChanged then
            itemBoxSelectedItemNum = itemBoxSliderNewVal
            itemBoxInputCountNewVal = tostring(itemBoxSliderNewVal)
            if checkIntegerInRange(itemBoxSliderNewVal, 0, 9999) then
                itemBoxConfirmBtnEnabled = true
            else
                itemBoxConfirmBtnEnabled = false
            end
        end
        if imgui.button(i18n.changeItemNumMinBtn, SMALL_BTN) then
            itemBoxSelectedItemNum = 0
            itemBoxInputCountNewVal = "0"
        end
        imgui.same_line()
        if imgui.button(i18n.changeItemNumMaxBtn, SMALL_BTN) then
            itemBoxSelectedItemNum = 9999
            itemBoxInputCountNewVal = "9999"
        end
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        itemBoxInputCountChanged, itemBoxInputCountNewVal = imgui.input_text(i18n.changeItemNumInput,
            itemBoxInputCountNewVal)
        if itemBoxInputCountChanged then
            local num = checkIntegerInRange(itemBoxInputCountNewVal, 0, 9999)
            if num then
                itemBoxConfirmBtnEnabled = true
                itemBoxSelectedItemNum = num
                itemBoxSliderNewVal = num
            else
                itemBoxConfirmBtnEnabled = false
            end
        end
        imgui.text_colored(i18n.changeItemTip, TIPS_COLOR)
        imgui.text_colored(i18n.changeItemWarning, ERROR_COLOR)
        imgui.begin_disabled(itemBoxSearchedItems == nil or
            #itemBoxSearchedItems == 0 or
            itemBoxSelectedItemFixedId == nil or
            not itemBoxConfirmBtnEnabled)
        if imgui.button(i18n.changeItemNumBtn, SMALL_BTN) then
            changeBoxItemNum(itemBoxSelectedItemFixedId, itemBoxSelectedItemNum)
            --clear()
            init()
        end
        imgui.end_disabled()
        local errDisplay = ""
        if not itemBoxConfirmBtnEnabled then
            errDisplay = i18n.changeItemNumInputError
        else
            errDisplay = ""
        end
        imgui.text_colored(errDisplay, ERROR_COLOR)
        imgui.end_disabled()

        imgui.new_line()
        imgui.begin_disabled(cBasicParam == nil)
        imgui.text(i18n.coinAndPtsEditorTitle)
        imgui.begin_disabled(originMoney + ADD_1E4 > MONEY_PTS_MAX)
        if imgui.button("Money: +" .. tostring(ADD_1E4), SMALL_BTN) then
            moneySliderVal = originMoney + ADD_1E4
            moneyChangedDiff = ADD_1E4
        end
        imgui.end_disabled()
        imgui.same_line()
        imgui.begin_disabled(originMoney + ADD_5E4 > MONEY_PTS_MAX)
        if imgui.button("Money: +" .. tostring(ADD_5E4), SMALL_BTN) then
            moneySliderVal = originMoney + ADD_5E4
            moneyChangedDiff = ADD_5E4
        end
        imgui.end_disabled()
        imgui.same_line()
        imgui.begin_disabled(originMoney + ADD_1E5 > MONEY_PTS_MAX)
        if imgui.button("Money: +" .. tostring(ADD_1E5), SMALL_BTN) then
            moneySliderVal = originMoney + ADD_1E5
            moneyChangedDiff = ADD_1E5
        end
        imgui.end_disabled()
        imgui.set_next_item_width(WINDOW_WIDTH_M)
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
            init()
        end

        imgui.begin_disabled(originPoints + ADD_1E4 > MONEY_PTS_MAX)
        if imgui.button("PTS: +" .. tostring(ADD_1E4), SMALL_BTN) then
            pointsSliderVal = originPoints + ADD_1E4
            pointsChangedDiff = ADD_1E4
        end
        imgui.end_disabled()
        imgui.same_line()
        imgui.begin_disabled(originPoints + ADD_5E4 > MONEY_PTS_MAX)
        if imgui.button("PTS: +" .. tostring(ADD_5E4), SMALL_BTN) then
            pointsSliderVal = originPoints + ADD_5E4
            pointsChangedDiff = ADD_5E4
        end
        imgui.end_disabled()
        imgui.same_line()
        imgui.begin_disabled(originPoints + ADD_1E5 > MONEY_PTS_MAX)
        if imgui.button("PTS: +" .. tostring(ADD_1E5), SMALL_BTN) then
            pointsSliderVal = originPoints + ADD_1E5
            pointsChangedDiff = ADD_1E5
        end
        imgui.end_disabled()
        imgui.set_next_item_width(WINDOW_WIDTH_M)
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
        imgui.new_line()
        imgui.text(i18n.modRepoTitle)
        imgui.text(i18n.modRepo)
        local repoBtnState = true
        local reposBtnRes = nil
        if imgui.button("Repo: " .. i18n.cpToClipboardBtn, SMALL_BTN) then
            repoBtnState, reposBtnRes = pcall(function()
                sdk.copy_to_clipboard(i18n.modRepo)
            end)
        end
        if not repoBtnState then
            imgui.text_colored(i18n.reframeworkVersionError, ERROR_COLOR)
        end
        imgui.text(i18n.nexusModPage)
        local modPageBtnState = true
        local modPageBtnRes = nil
        if imgui.button("Nexus Mod: " .. i18n.cpToClipboardBtn, SMALL_BTN) then
            modPageBtnState, modPageBtnRes = pcall(function()
                sdk.copy_to_clipboard(i18n.nexusModPage)
            end)
        end
        if not modPageBtnState then
            imgui.text_colored(i18n.reframeworkVersionError, ERROR_COLOR)
        end

        imgui.end_window()
    else
        clear()
        mainWindowState = false
        userConfig.mainWindowOpen = mainWindowState
        saveUserConfigJson(USER_CONFIG_PATH)
    end
end

local function itemTableWindow()
    local changed = nil
    imgui.set_next_window_size({ 480, 640 }, 4) -- 4 is ImGuiCond_FirstUseEver
    if imgui.begin_window(i18n.itemTableWindowTitle, itemWindowState, ImGuiWindowFlags_AlwaysAutoResize) then
        imgui.begin_table('search-group', 2, ImGuiTableFlags_NoSavedSettings)
        imgui.table_setup_column('', 0, 2)
        imgui.table_setup_column('', 0, 1)

        imgui.table_next_column()
        imgui.push_item_width(-1)
        changed, searchItem = imgui.input_text('', searchItemTarget)
        imgui.pop_item_width()
        if changed then
            searchItemTarget = searchItem
        end

        imgui.table_next_column()
        if imgui.button(i18n.clearBtn, { -0.001, 0 }) then
            searchItemTarget = nil
            searchItemResult = searchItemList(searchItemTarget)
        end
        imgui.end_table()

        if imgui.button(i18n.searchBtn, { -0.001, 0 }) then
            searchItemResult = searchItemList(searchItemTarget)
        end

        imgui.begin_table('table', 2, 17) -- 17 is ImGuiTableFlags_Resizable | ImGuiTableFlags_NoSavedSettings

        imgui.table_setup_column('', 0, 1)
        imgui.table_setup_column('', 0, 2)

        imgui.push_style_color(21, 0xff142D65)
        imgui.push_style_color(22, 0xff142D65)
        imgui.push_style_color(23, 0xff142D65)
        imgui.table_next_column()
        imgui.button(i18n.itemTableTitleID, { -0.001, 0 })
        imgui.table_next_column()
        imgui.button(i18n.itemTableTitleName, { -0.001, 0 })
        imgui.pop_style_color(3)

        for i = 1, #searchItemResult do
            imgui.table_next_column()
            imgui.button(searchItemResult[i].key, { -0.001, 0 })
            imgui.table_next_column()
            imgui.button(searchItemResult[i].value, { -0.001, 0 })
        end

        imgui.end_table()

        imgui.end_window()
    else
        itemWindowState = false
        userConfig.itemWindowOpen = itemWindowState
        saveUserConfigJson(USER_CONFIG_PATH)
    end
end

local function aboutWindow()
    if imgui.begin_window(i18n.aboutWindowsTitle, aboutWindowState, ImGuiWindowFlags_AlwaysAutoResize) then
        imgui.text(i18n.modContributorTitle)
        local contributorsStr = ""
        for i = 1, #i18n.modContributors do
            contributorsStr = contributorsStr .. i18n.modContributors[i]
            if i ~= #i18n.modContributors then
                contributorsStr = contributorsStr .. ", "
            end
        end
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        imgui.text(contributorsStr)

        imgui.new_line()
        imgui.text(i18n.modLicenseTitle)
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        imgui.text(i18n.modLicenseContent)

        imgui.new_line()
        imgui.text(i18n.modRepoTitle)
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        imgui.text(i18n.modRepo)
        local repoBtnState = true
        local reposBtnRes = nil
        if imgui.button("Repo: " .. i18n.cpToClipboardBtn, SMALL_BTN) then
            repoBtnState, reposBtnRes = pcall(function()
                sdk.copy_to_clipboard(i18n.modRepo)
            end)
        end
        if not repoBtnState then
            imgui.text_colored(i18n.reframeworkVersionError, ERROR_COLOR)
        end
        imgui.text(i18n.nexusModPage)
        local modPageBtnState = true
        local modPageBtnRes = nil
        if imgui.button("NexusMods: " .. i18n.cpToClipboardBtn, SMALL_BTN) then
            modPageBtnState, modPageBtnRes = pcall(function()
                sdk.copy_to_clipboard(i18n.nexusModPage)
            end)
        end
        if not modPageBtnState then
            imgui.text_colored(i18n.reframeworkVersionError, ERROR_COLOR)
        end

        imgui.new_line()
        imgui.text(i18n.otherLibsLicenseTitle)
        imgui.new_line()
        imgui.text(i18n.fontLicenseTitle)
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        imgui.text(i18n.fontLicenseContent)
        imgui.new_line()
        imgui.text(i18n.reframeworkLicenseTitle)
        imgui.set_next_item_width(WINDOW_WIDTH_M)
        imgui.text(i18n.reframeworkLicense)

        imgui.end_window()
    else
        aboutWindowState = false
        userConfig.aboutWindowOpen = aboutWindowState
    end
end

initIDAndFixedIDProjection()
loadI18NJson(ITEM_NAME_JSON_PATH)
loadUserConfigJson(USER_CONFIG_PATH)
searchItemResult = searchItemList(searchItemTarget)
getVersion()
MAX_VER_LT_OR_EQ_GAME_VER = compareVersions(GAME_VER, MAX_VERSION)

re.on_draw_ui(function()
    local mainWindowChanged = false
    local itemWindowChanged = false
    -- set the font
    if FONT ~= nil then
        imgui.push_font(FONT)
    end

    if imgui.tree_node(i18n.title) then
        mainWindowChanged, mainWindowState = imgui.checkbox(i18n.openMainWindow, mainWindowState)
        if mainWindowChanged then
            userConfig.mainWindowOpen = mainWindowState
            saveUserConfigJson(USER_CONFIG_PATH)
        end
        itemWindowChanged, itemWindowState = imgui.checkbox(i18n.openItemTableWindow, itemWindowState)
        if itemWindowChanged then
            userConfig.itemWindowOpen = itemWindowState
            saveUserConfigJson(USER_CONFIG_PATH)
        end
        if imgui.button(i18n.aboutWindowsTitle, SMALL_BTN) then
            aboutWindowState = not aboutWindowState
            userConfig.aboutWindowOpen = aboutWindowState
            saveUserConfigJson(USER_CONFIG_PATH)
        end
        imgui.tree_pop()
    end

    -- reset the font at the frame end
    if FONT ~= nil then
        imgui.pop_font()
    end
end)

re.on_frame(function()
    -- set the font
    if FONT ~= nil then
        imgui.push_font(FONT)
    end

    -- only display the window when REFramework is actually drawing its own UI
    if reframework:is_drawing_ui() then
        mainWindow()
        itemTableWindow()
        aboutWindow()
    end

    -- reset the font at the frame end
    if FONT ~= nil then
        imgui.pop_font()
    end
end)
