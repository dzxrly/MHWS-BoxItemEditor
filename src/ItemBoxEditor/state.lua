local function createEnumState()
    return {
        fixedIdToContent = {},
        contentToFixedId = {},
        fixedId = {},
        content = {}
    }
end

local function createState()
    return {
        isLoadLanguage = false,
        userConfig = {
            mainWindowOpen = false,
            itemWindowOpen = false,
            aboutWindowOpen = false,
            userLanguage = 1
        },
        itemEnum = createEnumState(),
        rareEnum = createEnumState(),
        itemTypeEnum = createEnumState(),
        cUserSaveParam = nil,
        itemDef = nil,
        baseItemList = nil,
        itemCombo = {
            displayText = {},
            itemNum = {},
            cData = {},
        },
        -- FilterType Projection: (i18n: typeFilterComboLabel)
        -- 1: filterNoLimitTitle 不限
        -- 2: typeFixedId = 0, isHeal = true 1治疗道具
        -- 3: typeFixedId = 0, isBattle = true 2战斗道具
        -- 4: typeFixedId = 0 3调合素材
        -- 5: typeFixedId = 2 4装备素材
        -- 6: typeFixedId = 3 5弩炮弹药
        -- 7: typeFixedId = 5 6特产/其他
        -- 8: typeFixedId = 2, isForMoney = true 7换金素材
        currentSelectedFilterTypeIdx = 1,
        currentSelectedRareIdx = 1,
        currentSelectedItemIdx = 1,
        currentInputItemNewNum = 0,
        currentMoney = 0,
        currentPts = 0,
        syncMoneyStr = nil,
        syncPtsStr = nil,
    }
end

local M = createState()

function M.resetState()
    local nextState = createState()

    for key, value in pairs(nextState) do
        M[key] = value
    end
end

return M
