local M = {}

-- runtime paths (set by entry file)
M.ITEM_NAME_JSON_PATH = ""
M.USER_CONFIG_PATH = ""

-- version info (set by entry file)
M.INTER_VERSION = "v1.9.19"
M.MAX_VERSION = "1.40.3.2"

-- constants
M.ITEM_ID_MAX = 974 -- app.ItemDef.ID.Max
M.NAME_LENGTH_MAX = 10
M.MONEY_PTS_MAX = 99999999
M.MONEY_PTS_ADD_VALUES = { 50000, 100000, 500000, 1000000 }
M.CLICK_COOLDOWN_SEC = 1
M.LARGE_BTN = Vector2f.new(300, 50)
M.SMALL_BTN = Vector2f.new(200, 40)
M.WINDOW_WIDTH_M = 300
M.WINDOW_WIDTH_S = 150
M.ERROR_COLOR = 0xeb4034ff
M.CHECKED_COLOR = 0xff74ff33
M.TIPS_COLOR = 0xff00c3ff

-- language mapping
M.LANG_DICT = {}
M.LANG_DICT["0"] = "ja-JP"    -- Japanese
M.LANG_DICT["1"] = "en-US"    -- English
M.LANG_DICT["9"] = "ko-KR"    -- Korean
M.LANG_DICT["10"] = "zh-Hant" -- Traditional Chinese
M.LANG_DICT["11"] = "zh-Hans" -- Simplified Chinese

return M
