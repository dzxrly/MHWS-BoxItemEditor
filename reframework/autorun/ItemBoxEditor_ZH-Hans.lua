-- Made By Egg Targaryen
-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For debug & Monster Hunter: Wilds
local INTER_VERSION = "v0.7"
local MAX_VERSION = "1.0.0.0"
local MONEY_PTS_MAX = 99999999
local LARGE_BTN = Vector2f.new(300, 50)
local SMALL_BTN = Vector2f.new(200, 40)
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

local function initBoxItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    cItemParam = cUserSaveParam:get_field("_Item")
    boxItemArray = cItemParam:get_field("_BoxItem")
    local existedShowInComboxPosIndex = 1
    for boxPosIndex = 0, #boxItemArray - 1 do
        --print("[" ..
        --    boxPosIndex ..
        --    "] Item ID:" ..
        --    boxItemArray[boxPosIndex]:get_field("ItemIdFixed") ..
        --    " - Count: " .. boxItemArray[boxPosIndex]:get_field("Num"))
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
        --print("[" ..
        --    pouchItemIndex ..
        --    "] Item ID:" ..
        --    pouchItemArray[pouchItemIndex]:get_field("ItemIdFixed") ..
        --    " - Count: " .. pouchItemArray[pouchItemIndex]:get_field("Num"))
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
    imgui.begin_window("道具箱编辑器", ImGuiWindowFlags_AlwaysAutoResize)
    getVersion()
    MAX_VER_LT_OR_EQ_GAME_VER = compareVersions(GAME_VER, MAX_VERSION)

    if MAX_VER_LT_OR_EQ_GAME_VER == false then
        imgui.text_colored("[警告] 当前的游戏版本不兼容该MOD: ", 0xeb4034ff)
        imgui.text_colored("游戏版本: " .. GAME_VER .. " > MOD兼容的最高版本: " .. MAX_VERSION, 0xeb4034ff)
        imgui.new_line()
    end

    imgui.text_colored("[警告] 使用该MOD前请务必备份存档 !!!", 0xeb4034ff)

    if imgui.button("读取道具箱", LARGE_BTN) then
        init()
    end

    imgui.new_line()
    imgui.text("道具数量修改:")
    imgui.begin_disabled(cItemParam == nil)
    existedComboChanged, existedSelectedIndex = imgui.combo("修改已存在的道具的数量", existedSelectedIndex,
        existedComboLabels)
    if existedComboChanged then
        existedSelectedItemFixedId = existedComboItemIdFixedValues[existedSelectedIndex]
        existedSelectedItemNum = existedComboItemNumValues[existedSelectedIndex]
    end
    existedSliderChanged, existedSliderNewVal = imgui.slider_int("选择新的数量 (1~9999)", existedSelectedItemNum, 1,
        9999)
    if existedSliderChanged then
        existedSelectedItemNum = existedSliderNewVal
    end
    if imgui.button("确认修改", SMALL_BTN) then
        changeBoxItemNum(existedSelectedItemFixedId, existedSelectedItemNum)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text("道具无中生有:")
    imgui.begin_disabled(cItemParam == nil)
    addNewInputChanged, addNewInputNewVal, start = imgui.input_text("输入物品ID", addNewItemId)
    if addNewInputChanged then
        addNewItemId = addNewInputNewVal
    end
    addNewSliderChanged, addNewSliderNewVal = imgui.slider_int("选择无中生有数量 (1~9999)", addNewItemNum, 1, 9999)
    if addNewSliderChanged then
        addNewItemNum = addNewSliderNewVal
    end
    if imgui.button("确认无中生有", SMALL_BTN) then
        addNewToPouchItem(addNewEmptyPouchItem, addNewItemId, addNewItemNum)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text("金币 & 调查点数修改:")
    imgui.begin_disabled(cBasicParam == nil)
    moneySilderChanged, moneySilderNewVal = imgui.slider_int(
        "选择新的金币数量 (" .. originMoney .. "~" .. (MONEY_PTS_MAX - originMoney) .. ")", moneySilderVal, originMoney,
        MONEY_PTS_MAX - originMoney)
    if moneySilderChanged then
        moneyChangedDiff = moneySilderNewVal - originMoney
        moneySilderVal = moneySilderNewVal
    end
    if imgui.button("确认金币修改", SMALL_BTN) then
        moneyAddFunc(cBasicParam, moneyChangedDiff)
        clear()
        init()
    end
    pointsSilderChange, pointsSilderNewVal = imgui.slider_int(
        "选择新的调查点数 (" .. originPoints .. "~" .. (MONEY_PTS_MAX - originPoints) .. ")", pointsSilderVal,
        originPoints,
        MONEY_PTS_MAX - originPoints)
    if pointsSilderChange then
        pointsChangedDiff = pointsSilderNewVal - originPoints
        pointsSilderVal = pointsSilderNewVal
    end
    if imgui.button("确认调查点数修改", SMALL_BTN) then
        pointAddFunc(cBasicParam, pointsChangedDiff)
        clear()
        init()
    end
    imgui.end_disabled()

    imgui.new_line()
    imgui.text("MOD版本: " .. INTER_VERSION)
    imgui.text("游戏版本: ")
    imgui.same_line()
    if MAX_VER_LT_OR_EQ_GAME_VER then
        imgui.text_colored(GAME_VER .. " [确认兼容]", 0xff74ff33)
    else
        imgui.text_colored(GAME_VER .. " [不兼容]", 0xeb4034ff)
    end

    imgui.end_window()
end)
