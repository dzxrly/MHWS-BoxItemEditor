--- 通用工具模块。
---
--- 提供日志、枚举解析、C# 集合读写、用户命令调度以及 i18n 通用辅助方法。
--- 该模块依赖 REFramework 运行时中的 `sdk` 全局对象。
---
--- @alias EnumState { fixedIdToContent: table, contentToFixedId: table, fixedId: table, content: table }
local M = {}
local pendingUserCmds = {}
local userCmdHookInstalled = false
local postUserCmdHook = nil
local modName = "UNKNOWN_MOD"
local enum_none = "NONE"
local enum_max = "MAX"
local enum_unknown = "UNKNOWN"
local enum_invalid = "INVALID"

--- 统一前缀打印。
--- @param ... any 可变参数日志内容。
local function modPrint(...)
    local argCount = select("#", ...)
    if argCount == 0 then
        print("[" .. modName .. "]")
        return
    end

    local parts = {}
    for i = 1, argCount do
        parts[i] = tostring(select(i, ...))
    end
    print("[" .. modName .. "] " .. table.concat(parts, "\t"))
end

--- 打印模块日志。
--- @param ... any 可变参数日志内容。
function M.log(...)
    modPrint(...)
end

--- 初始化模块名，用于日志前缀显示。
--- @param initModName string|nil 模块名称。
function M.init(initModName)
    if initModName == nil then
        modPrint("Warning: init called with nil mod name, keeping existing prefix")
        return
    end
    local name = tostring(initModName)
    if name ~= "" then
        modName = name
    end
end

--- 安装 GUI update 钩子，用于在主线程执行延迟命令。
local function installUserCmdHook()
    if userCmdHookInstalled then
        return
    end
    local methodDef = sdk.find_type_definition("app.GUIManager"):get_method("update()")
    if methodDef == nil then
        modPrint("Error: failed to install user command hook, app.GUIManager.update() not found")
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
                modPrint("executeUserCmd error: " .. tostring(err))
            end
        end
        if postUserCmdHook ~= nil then
            local ok, err = pcall(postUserCmdHook)
            if not ok then
                modPrint("postUserCmdHook error: " .. tostring(err))
            end
        end
    end, function(retval)
        return retval
    end)
end

--- 判断枚举名称是否为有效值（排除 NONE / MAX / UNKNOWN / INVALID）。
--- @param enumName string|number 枚举名称。
--- @return boolean
function M.isValidEnumName(enumName)
    -- filter enum_none, enum_max, enum_unknown, enum_invalid from enum
    return tostring(enumName) ~= enum_none and tostring(enumName) ~= enum_max and tostring(enumName) ~= enum_unknown and
        tostring(enumName) ~= enum_invalid
end

--- 将字节标志转换为布尔值（或布尔字符串）。
--- @param flagByte number|string 标志字节（通常 255 表示 true）。
--- @param isToString boolean|nil 是否返回字符串形式。
--- @return boolean|string
function M.flagByteToBool(flagByte, isToString)
    local flagBool = tostring(flagByte) == "255"
    if isToString then
        return tostring(flagBool)
    else
        return flagBool
    end
end

--- 向枚举状态容器追加一个枚举项。
--- @param enumState EnumState 枚举状态表，需包含 fixedIdToContent/contentToFixedId/fixedId/content 字段。
--- @param enumName string 枚举名称。
--- @param enumValue number 枚举值。
function M.appendEnumValue(enumState, enumName, enumValue)
    enumState.fixedIdToContent[enumValue] = enumName
    enumState.contentToFixedId[enumName] = enumValue
    table.insert(enumState.fixedId, enumValue)
    table.insert(enumState.content, enumName)
end

--- 解析指定类型下的静态枚举字段并写入枚举状态表。
--- @param typeName string 类型全名。
--- @param enumState EnumState 枚举状态表。
--- @param dedupeByValue boolean 是否按枚举值去重。
function M.parseEnumFields(typeName, enumState, dedupeByValue)
    local typeDef = sdk.find_type_definition(typeName)
    if typeDef == nil then
        modPrint("Error: enum type definition not found: " .. tostring(typeName))
        return
    end

    local enumFields = typeDef:get_fields()
    if enumFields == nil then
        modPrint("Error: enum fields not found for type: " .. tostring(typeName))
        return
    end

    local seenEnumValue = {}
    for _, field in ipairs(enumFields) do
        if field:is_static() then
            local enumName = field:get_name()
            local enumValue = field:get_data(nil)
            local valueKey = tostring(enumValue)
            if M.isValidEnumName(enumName) and (not dedupeByValue or not seenEnumValue[valueKey]) then
                seenEnumValue[valueKey] = true
                M.appendEnumValue(enumState, enumName, enumValue)
            end
        end
    end
end

--- 判断表是否为空，兼容字典结构。
--- @param table table|nil 要判断的表。
--- @return boolean
function M.isTableEmpty(table)
    -- compatible with dictionary
    if table == nil then
        return true
    end
    local len = 0
    for _, _ in pairs(table) do
        len = len + 1
    end
    return len == 0
end

--- 生成 ImGui 唯一文本（可见文本 + ID 后缀）。
--- @param text string 可见文本。
--- @param suffix string|number 唯一后缀。
--- @return string
function M.uniqueImguiText(text, suffix)
    return text .. "##" .. suffix
end

--- 枚举 C# Dictionary 对象，转换为 Lua 数组。
--- @param dictObj userdata|nil C# Dictionary 实例。
--- @return table[]
function M.CSharpDictEnumerator(dictObj)
    if not dictObj then
        return {}
    end
    local count = dictObj:call("get_Count")
    if not count or count == 0 then
        return {}
    end
    local entries = dictObj:get_field("entries")
    if not entries then
        entries = dictObj:get_field("_entries")
    end
    if not entries then
        return {}
    end
    local items = entries:get_elements()
    local result = {}
    for i, entry in pairs(items) do
        if entry then
            local k = entry:get_field("key")
            local v = entry:get_field("value")
            if k ~= nil and v ~= nil then
                table.insert(result, {
                    key = k,
                    value = v
                })
            end
        end
    end
    return result
end

--- 基于 Lua 表创建 `Dictionary<int, short>` C# 实例。
--- @param luaTable table<number, number>|nil 键值对表。
--- @return userdata|nil
function M.createCSharpDictInt32Int16Instance(luaTable)
    if luaTable == nil then
        modPrint("Error: createCSharpDictInt32Int16Instance received nil input table")
        return nil
    end
    local typeName = "System.Collections.Generic.Dictionary`2<System.Int32,System.Int16>"
    local dictTypeDef = sdk.find_type_definition(typeName)
    if dictTypeDef == nil then
        modPrint("createCSharpDictInt32Int16Instance: " .. typeName .. " not found")
        return nil
    end
    local dictInstance = dictTypeDef:create_instance()
    if dictInstance then
        dictInstance:call(".ctor()")
    else
        modPrint("Error: failed to create dictionary instance for type: " .. typeName)
        return nil
    end
    for k, v in pairs(luaTable) do
        local keyNum = tonumber(k)
        local valNum = tonumber(v)
        if keyNum and valNum then
            dictInstance:call("Add", keyNum, valNum)
        end
    end
    return dictInstance
end

--- 枚举 C# List 对象，转换为 Lua 数组。
--- @param listObj userdata|nil C# List 实例。
--- @return number[]
function M.CSharpListEnumerator(listObj)
    if not listObj then
        return {}
    end
    local count = listObj:call("get_Count")
    if not count then
        count = listObj:get_field("_size")
    end
    if not count or count == 0 then
        return {}
    end
    local items_array = listObj:get_field("_items")
    if not items_array then
        return {}
    end
    local raw_elements = items_array:get_elements()
    local result = {}
    for i = 0, count - 1 do
        local val = raw_elements[i]
        if val then
            local num_val = tonumber(sdk.to_int64(val))
            table.insert(result, num_val)
        end
    end
    return result
end

--- 基于 Lua 数组创建 `List<app.OtomonDef.ID_Fixed>` C# 实例。
--- @param luaArray number[]|nil Lua 数组。
--- @return userdata|nil
function M.createCSharpListInstance(luaArray)
    if not luaArray then
        modPrint("Error: createCSharpListInstance received nil input array")
        return nil
    end
    local typeName = "System.Collections.Generic.List`1<app.OtomonDef.ID_Fixed>"
    local listTypeDef = sdk.find_type_definition(typeName)
    if not listTypeDef then
        modPrint("Error: List type definition not found: " .. typeName)
        return nil
    end
    local listInstance = listTypeDef:create_instance()
    if listInstance then
        listInstance:call(".ctor()") -- 必须调用构造函数
    else
        modPrint("Error: failed to create list instance for type: " .. typeName)
        return nil
    end
    for _, value in ipairs(luaArray) do
        local num_val = tonumber(value)
        if num_val then
            listInstance:call("Add", num_val)
        end
    end
    return listInstance
end

--- 设置用户命令批处理完成后的回调。
--- @param hookFunc fun()|nil 回调函数。
function M.setUserCmdPostHook(hookFunc)
    postUserCmdHook = hookFunc
end

--- 将函数加入用户命令队列，在 GUI update 钩子内执行。
--- @param executeFunc fun()|nil 要执行的函数。
function M.executeUserCmd(executeFunc)
    if executeFunc == nil then
        modPrint("Warning: executeUserCmd called with nil function")
        return
    end
    installUserCmdHook()
    table.insert(pendingUserCmds, executeFunc)
end

--- 收集表中的数值型键。
--- @param sourceTable table<number|string, any>|nil 源表。
--- @return number[]
function M.collectTableNumberKeys(sourceTable)
    local keys = {}
    if sourceTable == nil then
        return keys
    end
    for key, _ in pairs(sourceTable) do
        local numericKey = tonumber(key)
        if numericKey ~= nil then
            table.insert(keys, numericKey)
        end
    end
    return keys
end

--- 判断列表中是否包含目标值。
--- @param list table|nil 列表。
--- @param targetValue any 目标值。
--- @return boolean
function M.containsValue(list, targetValue)
    if list == nil then
        return false
    end
    for _, value in ipairs(list) do
        if value == targetValue then
            return true
        end
    end
    return false
end

--- 在支持语言列表中选择有效语言，否则回退到默认语言。
--- @param languageIdx number|string|nil 待检测语言索引。
--- @param supportedLanguageList number[] 支持的语言索引列表。
--- @param defaultLanguageIdx number|nil 默认语言索引。
--- @return number
function M.getSupportedLanguageOrDefault(languageIdx, supportedLanguageList, defaultLanguageIdx)
    local defaultIdx = tonumber(defaultLanguageIdx) or 1
    local lang = tonumber(languageIdx)
    if lang == nil then
        return defaultIdx
    end
    if M.containsValue(supportedLanguageList, lang) then
        return lang
    end
    return defaultIdx
end

--- 按语言索引读取本地化文本，并在缺失时回退到默认语言。
--- @param languageTextMap table<number, table<string, string>> 文本映射表，形如 languageTextMap[lang][key]。
--- @param key string 文本键。
--- @param languageIdx number|string|nil 当前语言索引。
--- @param defaultLanguageIdx number|nil 默认语言索引。
--- @param ... string|number `string.format` 参数。
--- @return string
function M.getLocalizedText(languageTextMap, key, languageIdx, defaultLanguageIdx, ...)
    local fallbackLanguageIdx = tonumber(defaultLanguageIdx) or 1
    local selectedLanguageIdx = tonumber(languageIdx) or fallbackLanguageIdx
    local selectedLanguageText = nil
    if languageTextMap ~= nil then
        selectedLanguageText = languageTextMap[selectedLanguageIdx]
    end

    local text = nil
    if selectedLanguageText ~= nil then
        text = selectedLanguageText[key]
    end
    if text == nil and languageTextMap ~= nil and languageTextMap[fallbackLanguageIdx] ~= nil then
        text = languageTextMap[fallbackLanguageIdx][key]
    end
    if text == nil then
        return tostring(key)
    end
    if select("#", ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

--- 根据语言索引读取 GUID 对应的游戏内文本。
--- @param guid string|userdata 文本 GUID。
--- @param languageIdx number|string|nil 语言索引。
--- @return string
function M.getGuidTextByLanguage(guid, languageIdx)
    local lang = tonumber(languageIdx)
    if lang ~= nil then
        local viaGUIMsgGet = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid, via.Language)")
        if viaGUIMsgGet ~= nil then
            local text = viaGUIMsgGet(nil, guid, lang)
            if text ~= nil then
                return tostring(text)
            end
        end
    end
    return tostring(guid)
end

--- 从菜单选项对象读取角色语言索引。
--- @return number|nil
function M.getCharacterLanguageFromOption()
    local get_text_language = sdk.find_type_definition("via.gui.GUISystem"):get_method("get_MessageLanguage()")
    if get_text_language ~= nil then
        return get_text_language(nil)
    end
    return nil
end

--- 创建通用 i18n 上下文。
--- 返回对象字段：languageIdx/defaultLanguageIdx/text，方法：initLanguage/getUIText/getTextLanguage。
--- @param config table|nil i18n 配置，支持 defaultLanguageIdx:number 与 text:table<number, table<string, string>>。
--- @return table
function M.createI18n(config)
    local cfg = config or {}
    local context = {
        defaultLanguageIdx = tonumber(cfg.defaultLanguageIdx) or 1,
        languageIdx = tonumber(cfg.defaultLanguageIdx) or 1,
        text = cfg.text or {}
    }

    local function getCurrentTextLanguage()
        return tonumber(context.languageIdx) or context.defaultLanguageIdx
    end

    function context.initLanguage()
        local existingLangOpts = M.collectTableNumberKeys(context.text)
        local inGameLang = M.getCharacterLanguageFromOption()
        M.log("InGame language idx: " .. inGameLang)
        context.languageIdx = M.getSupportedLanguageOrDefault(inGameLang, existingLangOpts, context.defaultLanguageIdx)
        return context.languageIdx
    end

    function context.getUIText(key, ...)
        return M.getLocalizedText(context.text, key, getCurrentTextLanguage(), context.defaultLanguageIdx, ...)
    end

    function context.getTextLanguage(guid)
        local textLang = M.getCharacterLanguageFromOption() or getCurrentTextLanguage()
        return M.getGuidTextByLanguage(guid, textLang)
    end

    return context
end

return M
