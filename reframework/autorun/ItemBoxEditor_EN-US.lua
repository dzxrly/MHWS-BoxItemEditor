-- Made By Egg Targaryen
-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For debug & Monster Hunter: Wilds
local INTER_VERSION = "v0.6"
local MAX_VERSION = "1.0.0.0"
local MONEY_PTS_MAX = 99999999
local LARGE_BTN = Vector2f.new(300, 50)
local SMALL_BTN = Vector2f.new(200, 40)
local GAME_VER = nil
local MAX_VER_LT_OR_EQ_GAME_VER = true

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

local function initBoxItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    cItemParam = cUserSaveParam:get_field("_Item")
    boxItemArray = cItemParam:get_field("_BoxItem")
    local existedShowInComboxPosIndex = 1
    for boxPosIndex = 0, #boxItemArray - 1 do
        print("[" ..
            boxPosIndex ..
            "] Item ID:" ..
            boxItemArray[boxPosIndex]:get_field("ItemIdFixed") ..
            " - Count: " .. boxItemArray[boxPosIndex]:get_field("Num"))
        if boxItemArray[boxPosIndex]:get_field("Num") > 0 then
            local comboxItem = "Item ID:" ..
                boxItemArray[boxPosIndex]:get_field("ItemIdFixed") ..
                " - Count: " .. boxItemArray[boxPosIndex]:get_field("Num")
            -- print(comboxItem)
            existedComboLabels[existedShowInComboxPosIndex] = comboxItem
            existedComboItemIdFixedValues[existedShowInComboxPosIndex] = boxItemArray[boxPosIndex]:get_field(
                "ItemIdFixed")
            existedComboItemNumValues[existedShowInComboxPosIndex] = boxItemArray[boxPosIndex]:get_field("Num")
            existedShowInComboxPosIndex = existedShowInComboxPosIndex + 1
        end
    end
end

local function initPouchItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    cItemParam = cUserSaveParam:get_field("_Item")
    pouchItemArray = cItemParam:get_field("_PouchItem")
    for pouchItemIndex = 0, #pouchItemArray - 1 do
        print("[" ..
            pouchItemIndex ..
            "] Item ID:" ..
            pouchItemArray[pouchItemIndex]:get_field("ItemIdFixed") ..
            " - Count: " .. pouchItemArray[pouchItemIndex]:get_field("Num"))
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
    imgui.begin_window("ItemBox Editor", ImGuiWindowFlags_AlwaysAutoResize)
    getVersion()
    MAX_VER_LT_OR_EQ_GAME_VER = compareVersions(GAME_VER, MAX_VERSION)

    if MAX_VER_LT_OR_EQ_GAME_VER == false then
        imgui.text_colored("[Warning] Your game version is NOT compatible with this mod: ", 0xeb4034ff)
        imgui.text_colored("Game Version: " .. GAME_VER .. " > Compatible Version: " .. MAX_VERSION, 0xeb4034ff)
        imgui.new_line()
    end

    imgui.text_colored("[Warning] Please backup your save before using this mod !!!", 0xeb4034ff)

    if imgui.button("Read In-Game ItemBox", LARGE_BTN) then
        init()
    end

    imgui.new_line()
    imgui.text("Item Count Changer:")
    imgui.begin_disabled(cItemParam == nil)
    existedComboChanged, existedSelectedIndex = imgui.combo("Change Existed Item Number", existedSelectedIndex,
        existedComboLabels)
    if existedComboChanged then
        existedSelectedItemFixedId = existedComboItemIdFixedValues[existedSelectedIndex]
        existedSelectedItemNum = existedComboItemNumValues[existedSelectedIndex]
    end
    existedSliderChanged, existedSliderNewVal = imgui.slider_int("Select Changed Num (1~9999)", existedSelectedItemNum, 1,
        9999)
    if existedSliderChanged then
        existedSelectedItemNum = existedSliderNewVal
    end
    if imgui.button("Confirm Change", SMALL_BTN) then
        changeBoxItemNum(existedSelectedItemFixedId, existedSelectedItemNum)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text("Item Count Add:")
    imgui.begin_disabled(cItemParam == nil)
    addNewInputChanged, addNewInputNewVal, start = imgui.input_text("Enter the Item ID", addNewItemId)
    if addNewInputChanged then
        addNewItemId = addNewInputNewVal
    end
    addNewSliderChanged, addNewSliderNewVal = imgui.slider_int("Select Add Num (1~9999)", addNewItemNum, 1, 9999)
    if addNewSliderChanged then
        addNewItemNum = addNewSliderNewVal
    end
    if imgui.button("Confirm Add", SMALL_BTN) then
        addNewToPouchItem(addNewEmptyPouchItem, addNewItemId, addNewItemNum)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text("Money & Points Add:")
    imgui.begin_disabled(cBasicParam == nil)
    moneySilderChanged, moneySilderNewVal = imgui.slider_int(
        "Select New Money (" .. originMoney .. "~" .. (MONEY_PTS_MAX - originMoney) .. ")", moneySilderVal, originMoney,
        MONEY_PTS_MAX - originMoney)
    if moneySilderChanged then
        moneyChangedDiff = moneySilderNewVal - originMoney
        moneySilderVal = moneySilderNewVal
    end
    if imgui.button("Confirm Money Edit", SMALL_BTN) then
        moneyAddFunc(cBasicParam, moneyChangedDiff)
        clear()
        init()
    end
    pointsSilderChange, pointsSilderNewVal = imgui.slider_int(
        "Select New Points (" .. originPoints .. "~" .. (MONEY_PTS_MAX - originPoints) .. ")", pointsSilderVal,
        originPoints,
        MONEY_PTS_MAX - originPoints)
    if pointsSilderChange then
        pointsChangedDiff = pointsSilderNewVal - originPoints
        pointsSilderVal = pointsSilderNewVal
    end
    if imgui.button("Confirm Points Add", SMALL_BTN) then
        pointAddFunc(cBasicParam, pointsChangedDiff)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text("Mod Version: " .. INTER_VERSION)
    imgui.text("Game Version: ")
    imgui.same_line()
    if MAX_VER_LT_OR_EQ_GAME_VER then
        imgui.text_colored(GAME_VER .. " [Compatible]", 0xff74ff33)
    else
        imgui.text_colored(GAME_VER .. " [NOT Compatible]", 0xeb4034ff)
    end

    imgui.end_window()
end)
