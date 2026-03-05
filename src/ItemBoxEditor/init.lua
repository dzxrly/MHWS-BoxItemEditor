local coreApi = require("ItemBoxEditor.utils")
local state = require("ItemBoxEditor.state")

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
    state.cUserSaveParam = sdk.get_managed_singleton("app.SaveDataManager"):call("getCurrentUserSaveData()")
    state.itemDef = sdk.find_type_definition("app.ItemDef")

    initItemEnum()
    initRareEnum()
    initItemTypeEnum()

    coreApi.log("Initialization complete")
end

function M.onStart()
    M.modInit()
end

return M
