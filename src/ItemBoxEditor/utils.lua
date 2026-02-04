local state = require("ItemBoxEditor.state")

local M = {}
local pendingUserCmds = {}
local userCmdHookInstalled = false
local postUserCmdHook = nil

function M.getVersion()
    local sysService = sdk.get_native_singleton("via.SystemService")
    local sysServiceType = sdk.find_type_definition("via.SystemService")
    state.GAME_VER = sdk.call_native_func(sysService, sysServiceType, "get_ApplicationVersion()"):match(
            "Product:([^,]+)")
end

function M.compareVersions(version1, version2)
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

function M.checkItem(input)
    if input["_OutBox"] then
        return false
    end
    return true
end

function M.checkIntegerInRange(input_str, min_val, max_val)
    local num = tonumber(input_str)
    if num and num == math.floor(num) and num >= min_val and num <= max_val then
        return num
    end
    return nil
end

function M.searchItemList(target)
    local itemIndex = 0
    local itemMap = {}
    for index = 1, #state.itemNameJson do
        if state.itemNameJson and M.checkItem(state.itemNameJson[index]) then
            if target ~= nil then
                if string.lower(state.itemNameJson[index]._Name):match(string.lower(target)) then
                    itemMap[itemIndex] = {
                        key = tonumber(state.itemNameJson[index].fixedId),
                        value = state.itemNameJson[index]._Name
                    }
                    itemIndex = itemIndex + 1
                end
            else
                itemMap[itemIndex] = {
                    key = tonumber(state.itemNameJson[index].fixedId),
                    value = state.itemNameJson[index]._Name
                }
                itemIndex = itemIndex + 1
            end
        end
    end

    table.sort(itemMap, function(a, b)
        return a.key < b.key
    end)

    return itemMap
end

function M.filterCombo(array, filterSetting)
    local filteredArray = {}
    local filteredArrayLabel = {}
    local category = {
        _Type = nil,
        _Heal = false,
        _Battle = false,
        _OutBox = false
    }
    local tempArray = {}
    local switch = { -- { "无筛选条件", "治疗道具", "战斗道具", "调和素材", "制造材料", "弩炮弹药", "特产", "换金素材" }
        function()
            return
        end, function()
            category._Type = 0
            category._Heal = true
        end, function()
            category._Type = 0
            category._Battle = true
        end, function()
            category._Type = 0
        end, function()
            category._Type = 2
        end, function()
            category._Type = 3
        end, function()
            category._Type = 5
        end, function()
            category._Type = 2
            category._ForMoney = true
        end }
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

local function installUserCmdHook()
    if userCmdHookInstalled then
        return
    end
    local methodDef = sdk.find_type_definition("app.GUIManager"):get_method("update()")
    if methodDef == nil then
        return
    end
    userCmdHookInstalled = true
    sdk.hook(methodDef, function(args)
        if #pendingUserCmds == 0 then
            return
        end
        local current = pendingUserCmds
        pendingUserCmds = {}
        for i = 1, #current do
            local ok, err = pcall(current[i])
            if not ok then
                print("[ItemBoxEditor] executeUserCmd error: " .. tostring(err))
            end
        end
        if postUserCmdHook ~= nil then
            local ok, err = pcall(postUserCmdHook)
            if not ok then
                print("[ItemBoxEditor] postUserCmdHook error: " .. tostring(err))
            end
        end
    end, function(retval)
        return retval
    end)
end

function M.setUserCmdPostHook(hookFunc)
    postUserCmdHook = hookFunc
end

function M.executeUserCmd(executeFunc)
    if executeFunc == nil then
        return
    end
    installUserCmdHook()
    table.insert(pendingUserCmds, executeFunc)
end

return M
