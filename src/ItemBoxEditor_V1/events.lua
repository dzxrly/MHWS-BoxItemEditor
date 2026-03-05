local config = require("ItemBoxEditor.config")
local state = require("ItemBoxEditor.state")
local utils = require("ItemBoxEditor.utils")
local data_loader = require("ItemBoxEditor.data_loader")
local ui_render = require("ItemBoxEditor.ui_render")

local M = {}

function M.modInitalize()
    print("Initializing ItemBoxEditor...")
    state.isInitError = false
    state.initErrorMsg = nil

    local function initStep(stepFn, ...)
        local ok, err = pcall(stepFn, ...)
        if not ok then
            state.initErrorMsg = err
            state.isInitError = true
        end
        return ok
    end

    if not initStep(data_loader.initIDAndFixedIDProjection) then
        return
    end
    if not initStep(data_loader.loadI18NJson, config.ITEM_NAME_JSON_PATH) then
        return
    end
    if not initStep(data_loader.loadUserConfigJson, config.USER_CONFIG_PATH) then
        return
    end

    utils.getVersion()
    state.MAX_VER_LT_OR_EQ_GAME_VER = utils.compareVersions(state.GAME_VER, config.MAX_VERSION)
end

function M.onStartPlayable()
    local get_text_language = sdk.find_type_definition("app.OptionUtil"):get_method("getTextLanguage()")
    local default_lang = tostring(get_text_language(nil))
    if config.LANG_DICT[default_lang] ~= nil then
        state.userLanguage = config.LANG_DICT[default_lang]
    else
        state.userLanguage = "en-US" -- Default to English if language not found
    end
    print("Default Language: " .. default_lang .. " - User Language: " .. state.userLanguage)

    M.modInitalize()
    state.isLoadLanguage = true
end

function M.notTitleScreen()
    local playerManager = sdk.get_managed_singleton("app.PlayerManager")
    if playerManager == nil then
        return false
    end

    local currentNetworkPosition = playerManager:call("get_CurrentNetworkPosition()")
    if currentNetworkPosition == nil then
        return false
    end

    if currentNetworkPosition ~= 0 and currentNetworkPosition ~= 2 then
        return true
    end

    return false
end

function M.register()
    re.on_application_entry("UpdateScene", function()
        if not state.isLoadLanguage and M.notTitleScreen() then
            M.onStartPlayable()
        end
    end)

    sdk.hook(sdk.find_type_definition("app.GUIManager"):get_method("startPlayable()"), function()
    end, function()
        if not state.isLoadLanguage then
            M.onStartPlayable()
        end
    end)

    re.on_draw_ui(function()
        local mainWindowChanged = false
        local itemWindowChanged = false

        if imgui.tree_node("Item Box Editor") then
            if state.isLoadLanguage and not state.isInitError then
                imgui.text_colored(state.i18n.modFreeTips, config.TIPS_COLOR)
                imgui.begin_disabled(not state.isLoadLanguage)
                mainWindowChanged, state.mainWindowState = imgui.checkbox(state.i18n.openMainWindow,
                        state.mainWindowState)
                if mainWindowChanged then
                    state.userConfig.mainWindowOpen = state.mainWindowState
                    data_loader.saveUserConfigJson(config.USER_CONFIG_PATH)
                end
                itemWindowChanged, state.itemWindowState = imgui.checkbox(state.i18n.openItemTableWindow,
                        state.itemWindowState)
                if itemWindowChanged then
                    state.userConfig.itemWindowOpen = state.itemWindowState
                    data_loader.saveUserConfigJson(config.USER_CONFIG_PATH)
                end
                if imgui.button(state.i18n.aboutWindowsTitle, config.SMALL_BTN) then
                    state.aboutWindowState = not state.aboutWindowState
                    state.userConfig.aboutWindowOpen = state.aboutWindowState
                    data_loader.saveUserConfigJson(config.USER_CONFIG_PATH)
                end
                imgui.end_disabled()
            elseif not state.isLoadLanguage and not state.isInitError then
                imgui.text_colored("[Item Box Editor] Mod Initializing...", config.TIPS_COLOR)
            else
                imgui.text_colored("[Item Box Editor] Mod Initialization Error", config.ERROR_COLOR)
                imgui.text_colored("[Item Box Editor] " .. state.initErrorMsg, config.ERROR_COLOR)
            end
            imgui.tree_pop()
        end
    end)

    re.on_frame(function()
        local ref_font = imgui.load_font(nil, imgui.get_default_font_size())

        imgui.push_font(ref_font)

        -- only display the window when REFramework is actually drawing its own UI
        if reframework:is_drawing_ui() and state.isLoadLanguage then
            ui_render.mainWindow()
            ui_render.itemTableWindow()
            ui_render.aboutWindow()
        end

        imgui.pop_font(ref_font)
    end)
end

return M
