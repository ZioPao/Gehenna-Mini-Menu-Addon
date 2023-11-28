local PlayerHandler = require("DiceSystem_PlayerHandler")

---Reset a player mod data and sync it with the server
---@param playerIndex number
local function HandleResetTool(playerIndex)
    --local PlayerHandler = require("DiceSystem_PlayerHandler")
    local pl = getPlayer()
    local username = pl:getUsername()
    PlayerHandler.CleanModData(playerIndex, username)

    pl:Say("Cleaning data")

    local plInv = pl:getInventory()
    local diceResetTool = plInv:FindAndReturn("DiceResetTool")
    if diceResetTool then
        plInv:Remove(diceResetTool) -- Don't worry about the warning, umbrella must be wrong. This returns a inventoryitem
    end
end


local function OnFillInventoryObjectContextMenu(playerIndex, context, items)
    if items[1] then
        local item = items[1]

        if item.name == 'Dice System - Reset Tool' then
            context:addOption("Reset Dice Data", playerIndex, HandleResetTool)
        end
    end
end


Events.OnFillInventoryObjectContextMenu.Add(OnFillInventoryObjectContextMenu)
