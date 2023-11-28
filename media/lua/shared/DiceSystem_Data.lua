DICE_SYSTEM_MOD_STRING = "GehennaDiceSystem"
PLAYER_DICE_VALUES = {
    STATUS_EFFECTS = { "Stable", "Wounded", "Bleeding", "Charmed", "OnFire", "Prone", "Unconscious" },
    OCCUPATIONS = { "Unemployed", "Artist", "WageSlave", "Soldier", "Frontiersmen", "LawEnforcement", "FirstResponders",
        "Criminal", "BlueCollar", "Engineer", "WhiteCollar", "Clinician", "Academic", "Follower" },

    SKILLS = {"Brutality", "Resolve", "Awareness", "Chance", "Endurance"},      -- Max 15 points

    DEFAULT_HEALTH = 5,
    DEFAULT_MOVEMENT = 5,

    MAX_ALLOCATED_POINTS = 15,
    MAX_PER_SKILL_ALLOCATED_POINTS = 5,


    OCCUPATIONS_BONUS = {
        Unemployed      = { Brutality = 1, Chance = 1, Awareness = 1 },
        Artist          = { Chance = 2, Awareness = 1 },
        WageSlave       = { Chance = 2, Resolve = 1 },
        Soldier         = { Brutality = 2, Resolve = 1 },
        Frontiersmen    = { Brutality = 2, Endurance = 1 },
        LawEnforcement  = { Awareness = 2, Resolve = 1 },
        FirstResponders = { Awareness = 2, Endurance = 1 },
        Criminal        = { Chance = 2, Brutality = 1 },
        BlueCollar      = { Endurance = 2, Brutality = 1 },
        Engineer        = { Endurance = 2, Resolve = 1 },
        WhiteCollar     = { Endurance = 2, Chance = 1 },
        Clinician       = { Endurance = 2, Awareness = 1 },
        Academic        = { Awareness = 2, Chance = 1 },
        Follower        = { Chance = 2, Endurance = 1},
        --Dryad           = { Resolve = 2, Endurance = 2}
    }
}


COLORS_DICE_TABLES = {
    -- Normal colors for status effects
    STATUS_EFFECTS     = {
        Stable = { r = 0, g = 0.68, b = 0.94 },
        Wounded = { r = 0.95, g = 0.35, b = 0.16 },
        Bleeding = { r = 0.66, g = 0.15, b = 0.18 },
        Charmed = { r = 1, g = 1, b = 1 },
        OnFire = { r = 1, g = 0.2, b = 0 },
        Prone = { r = 0.04, g = 0.58, b = 0.27 },
        Unconscious = { r = 0.57, g = 0.15, b = 0.56 }
    },

    -- Used for color blind users
    STATUS_EFFECTS_ALT = {
        Stable = { r = 0.17, g = 0.94, b = 0.45 },     -- #2CF074
        Wounded = { r = 0.46, g = 0.58, b = 0.23 },    -- #75943A
        Bleeding = { r = 0.56, g = 0.15, b = 0.25 },   -- #8F263F
        Charmed = { r = 1, g = 1, b = 1 },            -- only white
        OnFire = { r = 1, g = 1, b = 1 },              -- only white
        Prone = { r = 0.35, g = 0.49, b = 0.64 },      -- #5A7EA3
        Unconscious = { r = 0.96, g = 0.69, b = 0.81 } -- #F5B0CF
    }
}


--**************************************--

DiceSystem_Common = {}

-- ---Returns the occupation bonus for a certain skill
-- ---@param occupation string
-- ---@param skill string
-- ---@return integer
-- function DiceSystem_Common.GetOccupationBonus(occupation, skill)
--     if PLAYER_DICE_VALUES.OCCUPATIONS_BONUS[occupation][skill] ~= nil then
--         return PLAYER_DICE_VALUES.OCCUPATIONS_BONUS[occupation][skill]
--     end
--     return 0
-- end

---Assign the correct color table for status effects
---@param colorsTable table
function DiceSystem_Common.SetStatusEffectsColorsTable(colorsTable)
    DiceSystem_Common.statusEffectsColors = colorsTable
end

--- Do a roll for a specific skill and print the result into chat. If something goes
---@param skill string
---@param points number
---@return number
function DiceSystem_Common.Roll(skill, points)
    local rolledValue = ZombRand(20) + 1
    local additionalMsg = ""
    if rolledValue == 1 then
        -- crit fail
        additionalMsg = "<SPACE> <RGB:1,0,0> CRITICAL FAILURE! "
    elseif rolledValue == 20 then
        -- crit success
        additionalMsg = "<SPACE> <RGB:0,1,0> CRITICAL SUCCESS! "
    end

    local finalValue = rolledValue + points
    local message = "(||DICE_SYSTEM_MESSAGE||) rolled " ..
        skill .. " " .. additionalMsg .. tostring(rolledValue) .. "+" .. tostring(points) .. "=" .. tostring(finalValue)

    -- send to chat
    if isClient() then
        DiceSystem_ChatOverride.NotifyRoll(message)
    end

    return finalValue
end

---Get the forename without the tabulations added by Buffy's bios
---@param plDescriptor SurvivorDesc
function DiceSystem_Common.GetForenameWithoutTabs(plDescriptor)
    local forenameWithTabs = plDescriptor:getForename()
    local forename = string.gsub(forenameWithTabs, "^%s*(%a+)", "%1")
    if forename == nil then forename = "" end
    return forename
end

if isDebugEnabled() then
    ---Writes a log in the console ONLY if debug is enabled
    ---@param text string
    function DiceSystem_Common.DebugWriteLog(text)
        --writeLog("DiceSystem", text)
        print("[DiceSystem] " .. text)
    end
else
    ---Placeholder, to prevent non essential calls
    function DiceSystem_Common.DebugWriteLog()
        return
    end
end
