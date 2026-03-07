local coreApi = require("ItemBoxEditor.utils")
local i18n = require("ItemBoxEditor.i18n")
local state = require("ItemBoxEditor.state")
local dataHelper = require("ItemBoxEditor.data_helper")
local config = require("ItemBoxEditor.config")
local ui = require("ItemBoxEditor.ui")
local init = require("ItemBoxEditor.init")

coreApi.init("Item Box Editor")

-- DO NOT CHANGE THE NEXT LINE, ONLY UPDATE THE VERSION NUMBER
local modVersion = "v2.0.0"
-- DO NOT CHANGE THE PREVIOUS LINE

local function onStartPlayable()
    i18n.initLanguage()
    dataHelper.loadUserConfigJson(config.USER_CONFIG_PATH)
    init.onStart()
    coreApi.setUserCmdPostHook(init.modInit())
    state.isLoadLanguage = true
end

local function notTitleScreen()
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

re.on_application_entry("UpdateScene", function()
    if not state.isLoadLanguage and notTitleScreen() then
        onStartPlayable()
    end
end)

sdk.hook(sdk.find_type_definition("app.GUIManager"):get_method("startPlayable()"), function()
end, function()
    if not state.isLoadLanguage then
        onStartPlayable()
    end
end)

re.on_draw_ui(function()
    local mainWindowChanged = false
    local itemWindowChanged = false

    if imgui.tree_node("Item Box Editor") then
        if state.isLoadLanguage then
            imgui.text_colored(i18n.getUIText("modFreeTips"), config.TIPS_COLOR)
            imgui.begin_disabled(not state.isLoadLanguage)
            mainWindowChanged, state.userConfig.mainWindowOpen = imgui.checkbox(i18n.getUIText("openMainWindow"),
                state.userConfig.mainWindowOpen)
            if mainWindowChanged then
                dataHelper.saveUserConfigJson(config.USER_CONFIG_PATH)
            end
            itemWindowChanged, state.userConfig.itemWindowOpen = imgui.checkbox(i18n.getUIText("openItemTableWindow"),
                state.userConfig.itemWindowOpen)
            if itemWindowChanged then
                dataHelper.saveUserConfigJson(config.USER_CONFIG_PATH)
            end
            if imgui.button(i18n.getUIText("aboutWindowTitle"), config.SMALL_BTN) then
                state.userConfig.aboutWindowOpen = not state.userConfig.aboutWindowOpen
                dataHelper.saveUserConfigJson(config.USER_CONFIG_PATH)
            end
            imgui.text("VERSION: " .. modVersion)
            imgui.end_disabled()
        else
            imgui.text_colored("[Item Box Editor] Mod Initializing...", config.TIPS_COLOR)
        end
        imgui.tree_pop()
    end
end)

re.on_frame(function()
    local ref_font = imgui.load_font(nil, imgui.get_default_font_size())

    imgui.push_font(ref_font)

    -- only display the window when REFramework is actually drawing its own UI
    if reframework:is_drawing_ui() and state.isLoadLanguage then
        ui.mainWindow()
        ui.itemTableWindow()
        ui.aboutWindow()
    end

    imgui.pop_font(ref_font)
end)
