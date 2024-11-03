-- Made By Egg Targaryen
-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For debug & Monster Hunter: Wilds Open Beta Version
local version = "v0.0.1 Beta"
local boxItemArray = nil
local pouchItemArray = nil
local cItemParam = nil

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

local function clear()
    boxItemArray = nil
    cItemParam = nil

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
end

local function initBoxItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    cItemParam = cUserSaveParam:get_field("_Item")
    boxItemArray = cItemParam:get_field("_BoxItem")
    local existedShowInComboxPosIndex = 1
    for boxPosIndex = 0, #boxItemArray - 1 do
        print("[" .. boxPosIndex .. "] Item ID:" .. boxItemArray[boxPosIndex]:get_field("ItemIdFixed") .. " - Count: " .. boxItemArray[boxPosIndex]:get_field("Num"))
        if boxItemArray[boxPosIndex]:get_field("Num") > 0 then
            local comboxItem = "Item ID:" .. boxItemArray[boxPosIndex]:get_field("ItemIdFixed") .. " - Count: " .. boxItemArray[boxPosIndex]:get_field("Num")
            -- print(comboxItem)
            existedComboLabels[existedShowInComboxPosIndex] = comboxItem
            existedComboItemIdFixedValues[existedShowInComboxPosIndex] = boxItemArray[boxPosIndex]:get_field("ItemIdFixed")
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
        print("[" .. pouchItemIndex .. "] Item ID:" .. pouchItemArray[pouchItemIndex]:get_field("ItemIdFixed") .. " - Count: " .. pouchItemArray[pouchItemIndex]:get_field("Num"))
        if pouchItemArray[pouchItemIndex]:get_field("Num") == 0 then
            addNewEmptyPouchItem = pouchItemArray[pouchItemIndex]
            break
        end
    end
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

re.on_draw_ui(function()
    imgui.begin_window("ItemBox Editor", ImGuiWindowFlags_AlwaysAutoResize)
    if imgui.button("Load ItemBox") then
        initBoxItem()
        initPouchItem()
    end

    imgui.new_line()
    existedComboChanged, existedSelectedIndex = imgui.combo("Change Existed Item Number", existedSelectedIndex, existedComboLabels)
    if existedComboChanged then
        existedSelectedItemFixedId = existedComboItemIdFixedValues[existedSelectedIndex]
        existedSelectedItemNum = existedComboItemNumValues[existedSelectedIndex]
    end
    existedSliderChanged, existedSliderNewVal = imgui.slider_int("Set New Num in 1 ~ 9999", existedSelectedItemNum, 1, 9999)
    if existedSliderChanged then
        existedSelectedItemNum = existedSliderNewVal
    end

    if imgui.button("Confirm Change") then
        changeBoxItemNum(existedSelectedItemFixedId, existedSelectedItemNum)
        clear()
        initBoxItem()
    end

    imgui.new_line()
    addNewInputChanged, addNewInputNewVal, start = imgui.input_text("Enter the Item ID", addNewItemId)
    if addNewInputChanged then
        addNewItemId = addNewInputNewVal
    end
    addNewSliderChanged, addNewSliderNewVal = imgui.slider_int("Select Num (1~9999)", addNewItemNum, 1, 9999)
    if addNewSliderChanged then
        addNewItemNum = addNewSliderNewVal
    end

    if imgui.button("Confirm Add") then
        addNewToPouchItem(addNewEmptyPouchItem, addNewItemId, addNewItemNum)
        clear()
        initPouchItem()
    end

    imgui.new_line()
    imgui.text("Version: " .. version)

    imgui.end_window()
end)
