local config = require("ItemBoxEditor.config")
local state = require("ItemBoxEditor.state")
local utils = require("ItemBoxEditor.utils")

local M = {}

function M.changeBoxItemNum(itemFixedId, changedNumber)
    utils.executeUserCmd(function()
        local itemID = state.itemIDAndFixedIDProjection[itemFixedId]
        local boxItem = state.cItemParam:call("getBoxItem(app.ItemDef.ID)", itemID)
        if boxItem == nil then
            state.cItemParam:call("changeItemBoxNum(app.ItemDef.ID, System.Int16)", itemID, changedNumber)
        else
            state.cItemParam:call("changeItemBoxNum(app.ItemDef.ID, System.Int16)", itemID,
                changedNumber - boxItem:get_field("Num"))
        end
        if changedNumber == 0 then
            for index = 1, #state.itemBoxList do
                if state.itemBoxList[index].fixedId == itemFixedId then
                    state.itemBoxList[index]["name"] = "[" ..
                        state.itemBoxList[index]["fixedId"] .. "]" .. state.itemBoxList[index]["_Name"] .. " - 0"
                    state.itemBoxList[index]["num"] = 0
                end
            end
        end
    end)
end

function M.moneyAddFunc(cBasicData, newMoney)
    utils.executeUserCmd(function()
        cBasicData:call("addMoney(System.Int32, System.Boolean)", newMoney, true)
    end)
end

function M.moneySubFunc(moneyDiff)
    utils.executeUserCmd(function()
        local payMoneyFunc = sdk.find_type_definition("app.FacilityUtil"):get_method("payMoney(System.Int32)")
        if payMoneyFunc ~= nil then
            payMoneyFunc(nil, moneyDiff)
        end
    end)
end

function M.pointAddFunc(cBasicData, newPoint)
    utils.executeUserCmd(function()
        cBasicData:call("addPoint(System.Int32, System.Boolean)", newPoint, true)
    end)
end

function M.pointSubFunc(pointDiff)
    utils.executeUserCmd(function()
        local payPointFunc = sdk.find_type_definition("app.FacilityUtil"):get_method("payPoint(System.Int32)")
        if payPointFunc ~= nil then
            payPointFunc(nil, pointDiff)
        end
    end)
end

function M.resetHunterName(cBasicData, newHunterName)
    utils.executeUserCmd(function()
        if newHunterName ~= nil and utf8.len(tostring(newHunterName)) > 0 and utf8.len(tostring(newHunterName)) <=
            config.NAME_LENGTH_MAX then
            cBasicData:call("setHunterName(System.String)", newHunterName)
        end
    end)
end

function M.resetOtomoName(cBasicData, newOtomoName)
    utils.executeUserCmd(function()
        if newOtomoName ~= nil and utf8.len(tostring(newOtomoName)) > 0 and utf8.len(tostring(newOtomoName)) <=
            config.NAME_LENGTH_MAX then
            cBasicData:call("setOtomoName(System.String)", newOtomoName)
        end
    end)
end

return M
