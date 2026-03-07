local mainWindow = require("ItemBoxEditor.components.main_window")
local itemTableWindow = require("ItemBoxEditor.components.item_table_window")
local aboutWindow = require("ItemBoxEditor.components.about_window")

local M = {}

function M.mainWindow()
    mainWindow.mainWindow()
end

function M.itemTableWindow()
    itemTableWindow.itemTableWindow()
end

function M.aboutWindow()
    aboutWindow.aboutWindow()
end

return M
