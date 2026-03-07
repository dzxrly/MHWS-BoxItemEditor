local coreApi = require("ItemBoxEditor.utils")
local state = require("ItemBoxEditor.state")
local dataHelper = require("ItemBoxEditor.data_helper")

local M = {}

local function initItemEnum()
    coreApi.parseEnumFields(
        "app.ItemDef.ID_Fixed",
        state.itemEnum,
        true
    )
end

local function initRareEnum()
    coreApi.parseEnumFields(
        "app.ItemDef.RARE_Fixed",
        state.rareEnum,
        true
    )
end

local function initItemTypeEnum()
    coreApi.parseEnumFields(
        "app.ItemDef.TYPE_Fixed",
        state.itemTypeEnum,
        true
    )
end

function M.modInit()
    coreApi.log("Initializing...")
    state.cBasicParam = sdk.get_managed_singleton("app.SaveDataManager"):call("getCurrentUserSaveData()"):get_field(
        "_BasicData")
    state.cItemParam = sdk.get_managed_singleton("app.SaveDataManager"):call("getCurrentUserSaveData()"):get_field(
        "_Item")
    state.itemDef = sdk.find_type_definition("app.ItemDef")
    state.payMoneyFunc = sdk.find_type_definition("app.FacilityUtil"):get_method(
        "payMoney(System.Int32)")
    state.payPtsFunc = sdk.find_type_definition("app.FacilityUtil"):get_method(
        "payPoint(System.Int32)")

    initItemEnum()
    initRareEnum()
    initItemTypeEnum()



    coreApi.log("Initialization complete")
end

function M.onStart()
    M.modInit()
    dataHelper.initBaseItemList()
end

return M
