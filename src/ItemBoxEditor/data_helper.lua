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
                    isOutBox = cData:get_field("_OutBox"),
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
    return not itemCData.isFix and
        not itemCData.isInfinit and
        not itemCData.isOutBox
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
                        isOutBox = itemCData.isOutBox,
                    }
                end
            end
        end
    else
        state.baseItemList = nil
        coreApi.log("Error: app.ItemDef.ID or app.ItemDef is not found")
    end
end

function M.getItemBoxInfo()
    if state.cUserSaveParam ~= nil and state.baseItemList ~= nil then
        local cItemParam = state.cUserSaveParam:get_field("_Item")
        if cItemParam ~= nil then
            local itemBox = cItemParam:get_field("_BoxItem")
            if itemBox ~= nil then
                state.itemCombo = {
                    displayText = {},
                    itemNum = {},
                    cData = {}
                }
                -- C# array begin from 0
                for index = 0, #itemBox - 1 do
                    local cItemWork = itemBox[index]
                    if cItemWork ~= nil then
                        local fixedId = cItemWork:get_field("ItemIdFixed")
                        local num = cItemWork:get_field("Num")
                        local itemCData = state.baseItemList[fixedId]
                        if itemCData ~= nil and isInFilter(fixedId) then
                            local displayText = itemCData.name ..
                                " - " ..
                                num ..
                                "##itemCombo_" ..
                                tostring(fixedId) ..
                                tostring(index)
                            table.insert(state.itemCombo.displayText, displayText)
                            table.insert(state.itemCombo.itemNum, num)
                            table.insert(state.itemCombo.cData, itemCData)
                        end
                    end
                end
            else
                coreApi.log("Error: cItemWork[] is not found")
            end
        else
            coreApi.log("Error: cItemParam is not found")
        end
    else
        coreApi.log("Error: cUserSaveParam is not found")
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
    if state.cUserSaveParam ~= nil then
        local cBasicParam = state.cUserSaveParam:get_field("_BasicData")
        if cBasicParam ~= nil then
            state.currentMoney = cBasicParam:call("getMoney()")
            state.currentPts = cBasicParam:call("getPoint()")
            state.syncMoneyStr = nil
            state.syncPtsStr = nil
        else
            coreApi.log("Error: cBasicParam is not found")
        end
    else
        coreApi.log("Error: cUserSaveParam is not found")
    end
end

function M.changeItemNum(itemId, changedNumDiff)
    if state.cUserSaveParam ~= nil and state.baseItemList ~= nil then
        local cItemParam = state.cUserSaveParam:get_field("_Item")
        if cItemParam ~= nil then
            cItemParam:call(
                "changeItemBoxNum(app.ItemDef.ID, System.Int16)",
                itemId,
                changedNumDiff
            )
            M.getItemBoxInfo()
        else
            coreApi.log("Error: cItemParam is not found")
        end
    else
        coreApi.log("Error: cUserSaveParam is not found")
    end
end

-- mode: 1 = money, 2 = pts
function M.changeMoneyAndPts(mode, changedDiff)
    if state.cUserSaveParam ~= nil then
        if mode == 1 then
            coreApi.log("Money changed diff = " .. tostring(changedDiff))
            if changedDiff >= 0 then
                local cBasicParam = state.cUserSaveParam:get_field("_BasicData")
                if cBasicParam ~= nil then
                    coreApi.executeUserCmd(function()
                        cBasicParam:call(
                            "addMoney(System.Int32, System.Boolean)",
                            math.abs(changedDiff),
                            false
                        )
                        M.getMoneyAndPts()
                    end)
                end
            else
                coreApi.executeUserCmd(function()
                    local payMoneyFunc = sdk.find_type_definition("app.FacilityUtil"):get_method(
                        "payMoney(System.Int32)")
                    if payMoneyFunc ~= nil then
                        payMoneyFunc(nil, math.abs(changedDiff))
                    else
                        coreApi.log("Error: payMoneyFunc is not found")
                    end
                    M.getMoneyAndPts()
                end)
            end
        elseif mode == 2 then
            coreApi.log("PTS changed diff = " .. tostring(changedDiff))
            if changedDiff >= 0 then
                local cBasicParam = state.cUserSaveParam:get_field("_BasicData")
                if cBasicParam ~= nil then
                    coreApi.executeUserCmd(function()
                        cBasicParam:call(
                            "addPoint(System.Int32, System.Boolean)",
                            math.abs(changedDiff),
                            false
                        )
                        M.getMoneyAndPts()
                    end)
                end
            else
                coreApi.executeUserCmd(function()
                    local payPointFunc = sdk.find_type_definition("app.FacilityUtil"):get_method(
                        "payPoint(System.Int32)")
                    if payPointFunc ~= nil then
                        payPointFunc(nil, math.abs(changedDiff))
                    else
                        coreApi.log("Error: payPointFunc is not found")
                    end
                    M.getMoneyAndPts()
                end)
            end
        end
    else
        coreApi.log("Error: cUserSaveParam is not found")
    end
end

function M.resetHunterName(newHunterName)
    if state.cUserSaveParam ~= nil then
        coreApi.executeUserCmd(function()
            state.cUserSaveParam:call("setHunterName(System.String)", newHunterName)
        end)
    else
        coreApi.log("Error: cUserSaveParam is not found")
    end
end

function M.resetOtomoName(newOtomoName)
    if state.cUserSaveParam ~= nil then
        coreApi.executeUserCmd(function()
            state.cUserSaveParam:call("setOtomoName(System.String)", newOtomoName)
        end)
    else
        coreApi.log("Error: cUserSaveParam is not found")
    end
end

return M
