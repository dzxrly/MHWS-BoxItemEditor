-- https://github.com/dzxrly/MHWS-BoxItemEditor
-- MIT License
-- For Monster Hunter: Wilds
-- !!! DO NOT MODIFY THE FOLLOWING CODE !!!
local ITEM_NAME_JSON_PATH = ""
local USER_CONFIG_PATH = ""
local ITEM_ID_MAX = 974 -- app.ItemDef.ID.Max
-- !!! DO NOT MODIFY THE ABOVE CODE !!!

-- Just change here can change every VERSION setting in all files
local INTER_VERSION = "v1.10.2"
local MAX_VERSION = "1.41.0.0"
-- Just change here can change every VERSION setting in all files END

local config = require("ItemBoxEditor.config")
local events = require("ItemBoxEditor.events")

config.ITEM_NAME_JSON_PATH = ITEM_NAME_JSON_PATH
config.USER_CONFIG_PATH = USER_CONFIG_PATH
config.ITEM_ID_MAX = ITEM_ID_MAX
config.INTER_VERSION = INTER_VERSION
config.MAX_VERSION = MAX_VERSION

events.register()
