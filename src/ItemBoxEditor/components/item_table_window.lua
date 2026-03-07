local state = require("ItemBoxEditor.state")
local coreApi = require("ItemBoxEditor.utils")
local i18n = require("ItemBoxEditor.i18n")
local config = require("ItemBoxEditor.config")
local dataHelper = require("ItemBoxEditor.data_helper")

local M = {}

local itemTable = {}
local searchText = ""
local isInitItemTable = false

local function getItemTable()
    if state.baseItemList ~= nil then
        itemTable = {}
        for fixedId, itemInfo in pairs(state.baseItemList) do
            if searchText == "" or string.find(string.lower(itemInfo.name), string.lower(searchText), 1, true) then
                table.insert(itemTable, {
                    fixedId = fixedId,
                    id = itemInfo.id,
                    name = itemInfo.name
                })
            end
        end
        coreApi.log("Set " .. #itemTable .. " len itemTable")
    else
        coreApi.log("Error: baseItemList is not found")
    end
end

function M.itemTableWindow()
    if imgui.begin_window(
            i18n.getUIText("itemTableWindowTitle"),
            state.userConfig.itemWindowOpen,
            config.IMGUI_AUTO_RESIZE
        ) then
        -- init table
        if not isInitItemTable then
            searchText = ""
            getItemTable()
            isInitItemTable = true
        end

        if imgui.begin_table("item_window_table_search", 3, config.IMGUI_TABLE_NONE) then
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 4)
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 1)
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 1)

            imgui.table_next_column()
            imgui.set_next_item_width(-1)
            _, searchText = imgui.input_text(
                "##item_win_input",
                searchText
            )
            imgui.table_next_column()
            if imgui.button(i18n.getUIText("clearBtn"), { -0.001, 0 }) then
                searchText = ""
                getItemTable()
            end
            imgui.table_next_column()
            if imgui.button(i18n.getUIText("searchBtn"), { -0.001, 0 }) then
                getItemTable()
            end

            imgui.end_table()
        end

        if imgui.begin_table("item_window_table_search", 2, config.IMGUI_TABLE_NONE) then
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 1)
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 3)

            imgui.table_next_column()
            imgui.begin_disabled(true)
            imgui.button(i18n.getUIText("itemTableTitleID"), { -0.001, 0 })
            imgui.end_disabled()

            imgui.table_next_column()
            imgui.begin_disabled(true)
            imgui.button(i18n.getUIText("itemTableTitleName"), { -0.001, 0 })
            imgui.end_disabled()

            imgui.end_table()
        end
        if imgui.begin_table("item_window_table_search", 2, config.IMGUI_TABLE_NONE) then
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 1)
            imgui.table_setup_column("", config.IMGUI_TABLE_COL_STRETCH, 3)
            for idx = 1, #itemTable do
                local itemInfo = itemTable[idx]
                imgui.table_next_row()
                imgui.table_next_column()
                imgui.begin_disabled(true)
                imgui.button(itemInfo.id .. "##" .. idx, { -0.001, 0 })
                imgui.end_disabled()

                imgui.table_next_column()
                if imgui.button(itemInfo.name .. "##" .. itemInfo.fixedId, { -0.001, 0 }) then
                    for comboIdx = 1, #state.itemCombo.cData do
                        if tostring(itemInfo.id) == tostring(state.itemCombo.cData[comboIdx].id) then
                            state.currentSelectedItemIdx = comboIdx
                            break
                        end
                    end
                    dataHelper.getItemBoxInfo()
                end
            end
            imgui.end_table()
        end

        imgui.end_window()
    else
        state.userConfig.itemWindowOpen = false
        dataHelper.saveUserConfigJson(config.USER_CONFIG_PATH)
    end
end

return M
