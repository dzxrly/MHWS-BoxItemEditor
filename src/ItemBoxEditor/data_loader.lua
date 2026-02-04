local config = require("ItemBoxEditor.config")
local state = require("ItemBoxEditor.state")
local utils = require("ItemBoxEditor.utils")

local M = {}

function M.initIDAndFixedIDProjection()
    local getFixedFromID = sdk.find_type_definition("app.ItemDef"):get_method("ItemId(app.ItemDef.ID)")
    if getFixedFromID ~= nil then
        for index = 1, config.ITEM_ID_MAX do
            local fixedID = getFixedFromID(nil, index)
            if fixedID ~= nil then
                state.itemIDAndFixedIDProjection[fixedID] = index
            end
        end
    else
        error("Error: Cannot find method app.ItemDef::ItemId(app.ItemDef.ID)")
    end
end

function M.loadUserConfigJson(jsonPath)
    if json ~= nil then
        local jsonFile = json.load_file(jsonPath)
        if jsonFile then
            state.userConfig.mainWindowOpen = jsonFile.mainWindowOpen
            state.userConfig.itemWindowOpen = jsonFile.itemWindowOpen
            state.userConfig.aboutWindowOpen = jsonFile.aboutWindowOpen
            state.mainWindowState = state.userConfig.mainWindowOpen
            state.itemWindowState = state.userConfig.itemWindowOpen
            state.aboutWindowState = state.userConfig.aboutWindowOpen
        else
            json.dump_file(jsonPath, state.userConfig)
        end
    else
        error("Error: Cannot load json lib")
    end
end

function M.saveUserConfigJson(jsonPath)
    if json ~= nil then
        json.dump_file(jsonPath, state.userConfig)
    end
end

function M.loadI18NJson(jsonPath)
    print("Loading I18N JSON file: " .. jsonPath)
    if json ~= nil then
        local jsonFile = json.load_file(jsonPath)
        if jsonFile ~= nil then
            state.i18n = jsonFile[state.userLanguage].I18N
            state.itemNameJson = jsonFile[state.userLanguage].ItemName
            local tempIndex = 1
            state.itemBoxList = {}
            print(state.itemNameJson[1]["_Name"])
            for index = 1, #state.itemNameJson do
                if utils.checkItem(state.itemNameJson[index]) then
                    state.itemBoxList[tempIndex] = state.itemNameJson[index]
                    state.itemBoxList[tempIndex]["name"] = "[" .. state.itemNameJson[index]["fixedId"] .. "]" ..
                            state.itemNameJson[index]["_Name"] .. " - 0"
                    state.itemBoxList[tempIndex]["num"] = 0
                    state.itemBoxList[tempIndex]["isUnknown"] = false
                    state.itemBoxList[tempIndex]["id"] = state.itemIDAndFixedIDProjection[state.itemNameJson[index]
                    ["fixedId"]]
                    print("Fixed ID: " .. state.itemBoxList[tempIndex]["fixedId"] .. " ID: " ..
                            state.itemBoxList[tempIndex]["id"])
                    tempIndex = tempIndex + 1
                end
            end
            table.sort(state.itemBoxList, function(a, b)
                return a._SortId < b._SortId
            end)
        else
            error("Error: Cannot load i18n json file")
        end
    else
        error("Error: Cannot load json lib")
    end
    state.typeFilterLabel = state.i18n.typeFilterComboLabel
    table.insert(state.typeFilterLabel, 1, state.i18n.filterNoLimitTitle)
    state.rareFilterLabel = { "1", "2", "3", "4", "5", "6", "7", "8" }
    table.insert(state.rareFilterLabel, 1, state.i18n.filterNoLimitTitle)
    state.searchItemResult = utils.searchItemList(state.searchItemTarget)
end

function M.initBoxItem()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData()")
    print("Hunter ID: " .. cUserSaveParam:get_field("HunterId"))
    state.cItemParam = cUserSaveParam:get_field("_Item")
    state.boxItemArray = state.cItemParam:call("get_BoxItem()")
    for boxPosIndex = 0, #state.boxItemArray - 1 do
        local boxItem = state.boxItemArray[boxPosIndex]
        local isNotInList = true
        if boxItem:get_field("Num") > 0 then
            local itemName = nil

            for index = 1, #state.itemNameJson do
                if state.itemNameJson[index].fixedId == boxItem:get_field("ItemIdFixed") then
                    isNotInList = false
                    itemName = state.itemNameJson[index]._Name
                end
            end

            if isNotInList then
                itemName = state.i18n.unknownItem
                local itemInfo = {
                    name = "[" .. tostring(boxItem:get_field("ItemIdFixed")) .. "]" .. itemName .. " - " ..
                            boxItem:get_field("Num"),
                    fixedId = boxItem:get_field("ItemIdFixed"),
                    num = boxItem:get_field("Num"),
                    _SortId = 99999,
                    isUnknown = true
                }
                table.insert(state.itemBoxList, itemInfo)
            else
                for tempIndex = 1, #state.itemBoxList do
                    if state.itemBoxList[tempIndex].fixedId == boxItem:get_field("ItemIdFixed") then
                        state.itemBoxList[tempIndex].name = "[" .. tostring(boxItem:get_field("ItemIdFixed")) .. "]" ..
                                itemName .. " - " .. boxItem:get_field("Num")
                        state.itemBoxList[tempIndex].num = boxItem:get_field("Num")
                        break
                    end
                end
            end
        end
    end
    table.sort(state.itemBoxList, function(a, b)
        return a._SortId < b._SortId
    end)
    state.itemBoxSearchedItems, state.itemBoxSearchedLabels = utils.filterCombo(state.itemBoxList, state.filterSetting)
    state.itemBoxSelectedItemFixedId = state.itemBoxSearchedItems[state.itemBoxComboIndex].fixedId
    state.itemBoxSelectedItemNum = state.itemBoxSearchedItems[state.itemBoxComboIndex].num
    state.itemBoxInputCountNewVal = tostring(state.itemBoxSelectedItemNum)
end

function M.initHunterBasicData()
    local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
    local cUserSaveParam = saveDataManager:call("getCurrentUserSaveData()")
    state.cBasicParam = cUserSaveParam:get_field("_BasicData")
    state.originMoney = state.cBasicParam:call("getMoney()")
    state.originPoints = state.cBasicParam:call("getPoint()")
end

function M.init()
    M.initBoxItem()
    M.initHunterBasicData()
end

utils.setUserCmdPostHook(M.init)

return M
