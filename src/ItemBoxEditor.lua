-- Made By Egg Targaryen
-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For Monster Hunter: Wilds

-- !!! DO NOT MODIFY THE FOLLOWING CODE !!!
local ITEM_NAME_JSON_PATH = ""
local LANG = ""
-- !!! DO NOT MODIFY THE ABOVE CODE !!!

-- Just change here can change every VERSION setting in all files
local INTER_VERSION = "v1.5"
local MAX_VERSION = "1.0.1.0"
-- Just change here can change every VERSION setting in all files END

local MONEY_PTS_MAX = 99999999
local LARGE_BTN = Vector2f.new(300, 50)
local SMALL_BTN = Vector2f.new(200, 40)
local ERROR_COLOR = 0xeb4034ff
local CHECKED_COLOR = 0xff74ff33
local TIPS_COLOR = 0xff00c3ff
local GAME_VER = nil
local MAX_VER_LT_OR_EQ_GAME_VER = true
local FONT = nil

if LANG ~= "EN-US" then
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
local itemBoxList = {}
local i18n = nil
-- NOT CHANGED VARIABLES END

-- window status
local mainWindowOpen = true
local itemWindowOpen = true
-- window status end

-- item table window
local searchItemTarget = nil
local searchItemResult = {}
-- item table window end

local boxItemArray = nil
local cItemParam = nil
local cBasicParam = nil

local itemBoxLabels = {}
local itemBoxComboChanged = false
local itemBoxComboIndex = nil
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
    itemBoxComboIndex = nil
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

local function checkIntegerInRange(input_str, min_val, max_val)
    local num = tonumber(input_str)
    if num and num == math.floor(num) and num >= min_val and num <= max_val then
        return num
    end
    return nil
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
            for key, value in pairs(itemNameJson) do
                if checkItemName(value) then
                    itemBoxList[tempIndex] = {
                        name = "[" .. key .. "]" .. value .. " - 0",
                        fixedId = tonumber(key),
                        num = 0,
                    }
                    tempIndex = tempIndex + 1
                end
            end
            table.sort(itemBoxList, function(a, b)
                return a.fixedId < b.fixedId
            end)
        end
    end
end

local function searchItemList(target)
    local itemIndex = 0
    local itemMap = {}
    for key, value in pairs(itemNameJson) do
        if checkItemName(value) then
            if target ~= nil then
                if string.lower(value):match(string.lower(target)) then
                    itemMap[itemIndex] = { key = tonumber(key), value = value }
                    itemIndex = itemIndex + 1
                end
            else
                itemMap[itemIndex] = { key = tonumber(key), value = value }
                itemIndex = itemIndex + 1
            end
        end
    end

    table.sort(itemMap, function(a, b)
        return a.key < b.key
    end)

    return itemMap
end

local function initBoxItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    cItemParam = cUserSaveParam:get_field("_Item")
    boxItemArray = cItemParam:call("get_BoxItem")

    for boxPosIndex = 0, #boxItemArray - 1 do
        local boxItem = boxItemArray[boxPosIndex]
        local isNotInList = true
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
            for tempIndex = 1, #itemBoxList do
                if itemBoxList[tempIndex].fixedId == boxItem:get_field("ItemIdFixed") then
                    itemBoxList[tempIndex] = itemInfo
                    isNotInList = false
                    break
                end
            end
            if isNotInList then
                table.insert(itemBoxList, itemInfo)
            end
        end
    end
    table.sort(itemBoxList, function(a, b)
        return a.fixedId < b.fixedId
    end)
    for itemIndex = 1, #itemBoxList do
        itemBoxLabels[itemIndex] = itemBoxList[itemIndex].name
    end
    itemBoxSearchedLabels = itemBoxLabels
    itemBoxSearchedItems = itemBoxList
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
    local boxItem = cItemParam:call("getBoxItem", itemFixedId - 1)
    if boxItem == nil then
        cItemParam:call("changeItemBoxNum", itemFixedId - 1, changedNumber)
    else
        cItemParam:call("changeItemBoxNum", itemFixedId - 1, changedNumber - boxItem:get_field("Num"))
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
    initHunterBasicData()
end


local function mainWindow()
    if imgui.begin_window(i18n.windowTitle, mainWindowOpen, ImGuiWindowFlags_AlwaysAutoResize) then
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
        imgui.new_line()
        imgui.text_colored(i18n.itemIdFileTip, TIPS_COLOR)
        imgui.text(i18n.changeItemNumTitle)
        imgui.begin_disabled(cItemParam == nil)
        itemBoxInputChanged, itemBoxInputNewVal = imgui.input_text(i18n.searchInput, itemBoxInputVal)
        if itemBoxInputChanged then
            itemBoxInputVal = itemBoxInputNewVal
            itemBoxComboIndex = nil
            if itemBoxInputNewVal == "" then
                itemBoxSearchedLabels = itemBoxLabels
                itemBoxSearchedItems = itemBoxList
            else
                itemBoxSearchedItems, itemBoxSearchedLabels = filterCombo(itemBoxList, itemBoxInputNewVal)
            end
            if #itemBoxSearchedItems > 0 then
                itemBoxSelectedItemFixedId = itemBoxSearchedItems[1].fixedId
                itemBoxSelectedItemNum = itemBoxSearchedItems[1].num
            end
        end
        itemBoxComboChanged, itemBoxComboIndex = imgui.combo(i18n.changeItemNumCombox, itemBoxComboIndex,
            itemBoxSearchedLabels)
        if itemBoxComboChanged then
            itemBoxSelectedItemFixedId = itemBoxSearchedItems[itemBoxComboIndex].fixedId
            itemBoxSelectedItemNum = itemBoxSearchedItems[itemBoxComboIndex].num
        end
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
            clear()
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
    else
        clear()
        mainWindowOpen = false
    end
end

local function itemTableWindow()
    local changed = nil
    imgui.set_next_window_size({ 480, 640 }, 4) -- 4 is ImGuiCond_FirstUseEver
    if imgui.begin_window(i18n.itemTableWindowTitle, itemWindowOpen, ImGuiWindowFlags_AlwaysAutoResize) then
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
        itemWindowOpen = false
    end
end

loadI18NJson(ITEM_NAME_JSON_PATH)
searchItemResult = searchItemList(searchItemTarget)
getVersion()
MAX_VER_LT_OR_EQ_GAME_VER = compareVersions(GAME_VER, MAX_VERSION)

re.on_draw_ui(function()
    local changed = false
    -- set the font
    if FONT ~= nil then
        imgui.push_font(FONT)
    end

    if imgui.tree_node(i18n.title) then
        changed, mainWindowOpen = imgui.checkbox(i18n.openMainWindow, mainWindowOpen)
        changed, itemWindowOpen = imgui.checkbox(i18n.openItemTableWindow, itemWindowOpen)

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
    end

    -- reset the font at the frame end
    if FONT ~= nil then
        imgui.pop_font()
    end
end)
