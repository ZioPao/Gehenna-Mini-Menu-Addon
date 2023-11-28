require("UI/DiceSystem_StatusEffectsUI")

local offsets = { "-200", "-150", "-100", "-50", "0", "50", "100", "150", "200" }
local OPTIONS = {
    enableColorBlind = false,
    offsetStatusEffects = 5, -- Should be equal to "0"
}

local function CheckOptions()
    --* Color blindness check
    if OPTIONS.enableColorBlind then
        --print("Color Blind colors")
        DiceSystem_Common.SetStatusEffectsColorsTable(COLORS_DICE_TABLES.STATUS_EFFECTS_ALT)
    else
        --print("Normal colors")
        DiceSystem_Common.SetStatusEffectsColorsTable(COLORS_DICE_TABLES.STATUS_EFFECTS)
    end

    --local amount = offsets[OPTIONS.offsetStatusEffects]
    --StatusEffectsHandler.SetUserOffset(tonumber(amount))
end

-----------------------------

if ModOptions and ModOptions.getInstance then
    local modOptions = ModOptions:getInstance(OPTIONS, DICE_SYSTEM_MOD_STRING, "Gehenna RP - Dice System")

    local enableColorBlind = modOptions:getData("enableColorBlind")
    enableColorBlind.name = "Colorblind mode"
    enableColorBlind.tooltip = "Enable colorblind alternative colors"

    function enableColorBlind:OnApplyInGame(val)
        --print("Reapplying")
        if not val then
            DiceSystem_Common.SetStatusEffectsColorsTable(COLORS_DICE_TABLES.STATUS_EFFECTS)
        else
            DiceSystem_Common.SetStatusEffectsColorsTable(COLORS_DICE_TABLES.STATUS_EFFECTS_ALT)
        end
    end

    local offsetStatusEffects = modOptions:getData("offsetStatusEffects")
    for i = 1, #offsets do
        offsetStatusEffects[i] = offsets[i]
    end


    -- offsetStatusEffects.name = "Status Effects offset"
    -- offsetStatusEffects.tooltip = "Set the offset for the status effects on top of the players heads"
    -- function offsetStatusEffects:OnApplyInGame(val)
    --     local amount = offsets[val]
    --     StatusEffectsHandler.SetUserOffset(tonumber(amount))
    -- end

    Events.OnGameStart.Add(CheckOptions)
else
    --print("Setting normal colors")
    DiceSystem_Common.SetStatusEffectsColorsTable(COLORS_DICE_TABLES.STATUS_EFFECTS)
    --StatusEffectsHandler.SetUserOffset(0)
end
