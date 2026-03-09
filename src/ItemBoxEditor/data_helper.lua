local state = require("ItemBoxEditor.state")
local coreApi = require("ItemBoxEditor.utils")
local i18n = require("ItemBoxEditor.i18n")
local config = require("ItemBoxEditor.config")

local M = {}

local function getItemDataCData(itemId)
    if state.itemDef ~= nil then
        local dataFunc = state.itemDef:get_method("Data(app.ItemDef.ID)")
        if dataFunc ~= nil then
            local cData = dataFunc(nil, itemId)
            if cData ~= nil then
                return {
                    id = itemId,
                    fixedId = cData:get_field("_ItemId"),
                    nameGuid = cData:get_field("_RawName"),
                    sortId = cData:get_field("_SortId"),
                    rareFixedId = cData:get_field("_Rare"),
                    typeFixedId = cData:get_field("_Type"),
                    isFix = cData:get_field("_Fix"),
                    isShikyu = cData:get_field("_Shikyu"),
                    isInfinit = cData:get_field("_Infinit"),
                    isHeal = cData:get_field("_Heal"),
                    isBattle = cData:get_field("_Battle"),
                    isSpecial = cData:get_field("_Special"),
                    isForMoney = cData:get_field("_ForMoney"),
                    isOutBox = cData:get_field("_OutBox")
                }
            end
        end
    end
    return nil
end

local function getItemName(nameGuid)
    local itemName = tostring(i18n.getTextLanguage(nameGuid))
    -- check if "Reject" keyword in name
    for _, keyword in ipairs(config.IGNORED_KEYWORDS) do
        if string.find(itemName, keyword) then
            return nil
        end
    end
    return itemName
end

local function isEditableItem(itemCData)
    return not itemCData.isFix and not itemCData.isInfinit and not itemCData.isOutBox
end

local function isInFilter(itemFixedId)
    if state.baseItemList ~= nil and state.baseItemList[itemFixedId] ~= nil then
        local cData = state.baseItemList[itemFixedId]
        -- type filter
        local typeFlag = false
        if state.currentSelectedFilterTypeIdx == 1 then
            typeFlag = true
        elseif state.currentSelectedFilterTypeIdx == 2 then
            typeFlag = cData.typeFixedId == 0 and cData.isHeal
        elseif state.currentSelectedFilterTypeIdx == 3 then
            typeFlag = cData.typeFixedId == 0 and cData.isBattle
        elseif state.currentSelectedFilterTypeIdx == 4 then
            typeFlag = cData.typeFixedId == 0
        elseif state.currentSelectedFilterTypeIdx == 5 then
            typeFlag = cData.typeFixedId == 2
        elseif state.currentSelectedFilterTypeIdx == 6 then
            typeFlag = cData.typeFixedId == 3
        elseif state.currentSelectedFilterTypeIdx == 7 then
            typeFlag = cData.typeFixedId == 5
        elseif state.currentSelectedFilterTypeIdx == 8 then
            typeFlag = cData.typeFixedId == 2 and cData.isForMoney
        end

        -- rare filter
        local rareFlag = false
        if state.currentSelectedRareIdx == 1 then
            rareFlag = true
        elseif state.currentSelectedRareIdx > 1 then
            for i = 1, state.currentSelectedRareIdx - 1 do
                if cData.rareFixedId == state.rareEnum.fixedId[i] then
                    rareFlag = true
                    break
                end
            end
        end

        return typeFlag and rareFlag
    end
    return false
end

function M.initBaseItemList()
    if state.itemEnum ~= nil and state.itemDef ~= nil then
        state.baseItemList = {}
        for index = 1, #state.itemEnum.content do
            local itemCData = getItemDataCData(state.itemEnum.fixedId[index])
            if itemCData ~= nil and isEditableItem(itemCData) then
                local itemName = getItemName(itemCData.nameGuid)
                if itemName ~= nil and itemName ~= "" then
                    state.baseItemList[itemCData.fixedId] = {
                        id = itemCData.id,
                        name = itemName,
                        sortId = itemCData.sortId,
                        rareFixedId = itemCData.rareFixedId,
                        typeFixedId = itemCData.typeFixedId,
                        isFix = itemCData.isFix,
                        isShikyu = itemCData.isShikyu,
                        isInfinit = itemCData.isInfinit,
                        isHeal = itemCData.isHeal,
                        isBattle = itemCData.isBattle,
                        isSpecial = itemCData.isSpecial,
                        isForMoney = itemCData.isForMoney,
                        isOutBox = itemCData.isOutBox
                    }
                end
            end
        end
    else
        state.baseItemList = nil
        coreApi.log("Error: app.ItemDef.ID or app.ItemDef is not found")
    end
end

function M.isInBaseListInfo(itemObj, searchKeyword)
    searchKeyword = string.lower(tostring(searchKeyword) or "")
    if searchKeyword == "" then
        return true
    end

    local id = string.lower(tostring(itemObj.id))
    local name = string.lower(tostring(itemObj.name))
    if string.find(id, searchKeyword, 1, true) or
        string.find(name, searchKeyword, 1, true) then
        return true
    end

    return false
end

function M.getItemBoxInfo()
    if state.baseItemList ~= nil and state.cItemParam ~= nil then
        local itemBox = state.cItemParam:get_field("_BoxItem")
        if itemBox ~= nil then
            local itemBoxList = {}
            -- C# array begin from 0
            for idx = 0, #itemBox - 1 do
                local cItemWork = itemBox[idx]
                itemBoxList[cItemWork:get_field("ItemIdFixed")] = cItemWork:get_field("Num")
            end
            state.itemCombo = {
                displayText = {},
                itemNum = {},
                cData = {}
            }
            for fixedId, itemObj in pairs(state.baseItemList) do
                if isInFilter(fixedId) and
                    M.isInBaseListInfo(itemObj, state.mainWindowSearchText)
                then
                    local num = itemBoxList[fixedId] or 0
                    local displayText = itemObj.name .. " - " .. num .. "##itemCombo_" .. tostring(fixedId)
                    table.insert(state.itemCombo.displayText, displayText)
                    table.insert(state.itemCombo.itemNum, num)
                    table.insert(state.itemCombo.cData, itemObj)
                end
            end
        else
            coreApi.log("Error: cItemWork[] is not found")
        end
    else
        coreApi.log("Error: cItemParam is not found")
    end
end

function M.loadUserConfigJson(jsonPath)
    if json ~= nil then
        local jsonFile = json.load_file(jsonPath)
        if jsonFile then
            state.userConfig.mainWindowOpen = jsonFile.mainWindowOpen
            state.userConfig.itemWindowOpen = jsonFile.itemWindowOpen
            state.userConfig.aboutWindowOpen = jsonFile.aboutWindowOpen
        else
            json.dump_file(jsonPath, state.userConfig)
        end
    else
        coreApi.log("Error: Cannot load json lib")
    end
end

function M.saveUserConfigJson(jsonPath)
    if json ~= nil then
        json.dump_file(jsonPath, state.userConfig)
    else
        coreApi.log("Error: Cannot load json lib")
    end
end

function M.getMoneyAndPts()
    if state.cBasicParam ~= nil then
        state.currentMoney = state.cBasicParam:call("getMoney()")
        state.currentPts = state.cBasicParam:call("getPoint()")
        state.syncMoneyStr = nil
        state.syncPtsStr = nil
    else
        coreApi.log("Error: cBasicParam is not found")
    end
end

function M.changeItemNum(itemId, changedNumDiff)
    if state.baseItemList ~= nil and state.cItemParam ~= nil then
        state.cItemParam:call("changeItemBoxNum(app.ItemDef.ID, System.Int16)", itemId, changedNumDiff)
        M.getItemBoxInfo()
    else
        coreApi.log("Error: cItemParam is not found")
    end
end

-- mode: 1 = money, 2 = pts
function M.changeMoneyAndPts(mode, changedDiff)
    if state.cBasicParam ~= nil and state.payMoneyFunc ~= nil and state.payPtsFunc ~= nil then
        if mode == 1 then
            coreApi.log("Money changed diff = " .. tostring(changedDiff))
            if changedDiff >= 0 then
                coreApi.executeUserCmd(function()
                    state.cBasicParam:call("addMoney(System.Int32, System.Boolean)", math.abs(changedDiff), false)
                    M.getMoneyAndPts()
                end)
            else
                coreApi.executeUserCmd(function()
                    state.payMoneyFunc(nil, math.abs(changedDiff))
                    M.getMoneyAndPts()
                end)
            end
        elseif mode == 2 then
            coreApi.log("PTS changed diff = " .. tostring(changedDiff))
            if changedDiff >= 0 then
                coreApi.executeUserCmd(function()
                    state.cBasicParam:call("addPoint(System.Int32, System.Boolean)", math.abs(changedDiff), false)
                    M.getMoneyAndPts()
                end)
            else
                coreApi.executeUserCmd(function()
                    state.payPointFunc(nil, math.abs(changedDiff))
                    M.getMoneyAndPts()
                end)
            end
        end
    else
        coreApi.log("Error: cItemParam/payMoneyFunc/payPtsFunc is not found")
    end
end

function M.resetHunterName(newHunterName)
    if state.cBasicParam ~= nil then
        coreApi.executeUserCmd(function()
            state.cBasicParam:call("setHunterName(System.String)", newHunterName)
        end)
    else
        coreApi.log("Error: cBasicParam is not found")
    end
end

function M.resetOtomoName(newOtomoName)
    if state.cBasicParam ~= nil then
        coreApi.executeUserCmd(function()
            state.cBasicParam:call("setOtomoName(System.String)", newOtomoName)
        end)
    else
        coreApi.log("Error: cBasicParam is not found")
    end
end

return M
