-- Made By Egg Targaryen
-- For debug & Monster Hunter: Wilds Open Beta Version
local boxItemArray = nil

local comboLabels = {}
local comboItemIdFixedValues = {}
local comboItemNumValues = {}
local comboChanged = false
local selectedIndex = nil
local selectedItemFixedId = nil
local selectedItemNum = nil

local function initBoxItem()
    showInCombo = {}
    changed = false
    selectedIndex = nil
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    boxItemArray = cUserSaveParam:get_field("_Item"):get_field("_BoxItem")
    local showInComboxPosIndex = 1
    for boxPosIndex = 0, #boxItemArray - 1 do
        if boxItemArray[boxPosIndex]:get_field("Num") > 0 then
            local comboxItem = "Item ID:" .. boxItemArray[boxPosIndex]:get_field("ItemIdFixed") .. " - Count: " .. boxItemArray[boxPosIndex]:get_field("Num")
            print(comboxItem)
            comboLabels[showInComboxPosIndex] = comboxItem
            comboItemIdFixedValues[showInComboxPosIndex] = boxItemArray[boxPosIndex]:get_field("ItemIdFixed")
            comboItemNumValues[showInComboxPosIndex] = boxItemArray[boxPosIndex]:get_field("Num")
            showInComboxPosIndex = showInComboxPosIndex + 1
        end
    end
end

local function changeBoxItemNum(itemFixedId, changedNumber)
    if changedNumber >= 0 then
        for boxPosIndex = 0, #boxItemArray - 1 do
            if boxItemArray[boxPosIndex]:get_field("ItemIdFixed") == itemFixedId then
                local itemEnumId = boxItemArray[boxPosIndex]:call("get_ItemId")
                boxItemArray[boxPosIndex]:call("set", itemEnumId, changedNumber)
            end
        end
    end
end

re.on_draw_ui(function()
    imgui.begin_window("ItemBox Editor", ImGuiWindowFlags_AlwaysAutoResize)
    if imgui.button("Load ItemBox") then
        initBoxItem()
    end
    comboChanged, selectedIndex = imgui.combo("Change Existed Item Number", selectedIndex, comboLabels)
    if comboChanged then
        selectedItemFixedId = comboItemIdFixedValues[selectedIndex]
        selectedItemNum = comboItemNumValues[selectedIndex]
    end
    sliderChanged, sliderNewVal = imgui.slider_int("Set New Num in 1 ~ 9999", selectedItemNum, 1, 9999)
    if sliderChanged then
        changeBoxItemNum(selectedItemFixedId, sliderNewVal)
        selectedItemNum = sliderNewVal
        initBoxItem()
    end
    imgui.end_window()
end)
