-- Player data saved locally here
DICE_CLIENT_MOD_DATA = {}

local PlayerHandler = {
    handlers = {}
}


------ 
--* Static functions
------

---Get a certain player active status effects from the cache
---@return table
PlayerHandler.GetActiveStatusEffectsByUsername = function(username)
    local pl = getPlayerFromUsername(username)

    if pl then
        local plID = pl:getOnlineID()
        local effectsTable = StatusEffectsHandler.nearPlayersStatusEffects[plID]
        if effectsTable == nil then return {} else return effectsTable end
    end

    return {}
end


--* Admin functions 

---Start cleaning process for a specific user, for admin only
---@param userID number
PlayerHandler.CleanModData = function(userID, username)
    sendClientCommand(DICE_SYSTEM_MOD_STRING, "ResetServerDiceData", { userID = userID, username = username })
end

---Check if player is initialized and ready to use the system
---@param username any
---@return boolean
PlayerHandler.CheckInitializedStatus = function(username)
    if DICE_CLIENT_MOD_DATA[username] then
        return DICE_CLIENT_MOD_DATA[username].isInitialized
    else
        return false
    end
end

--------------------------------
--* Global mod data *--

function OnConnected()
    --print("Requested global mod data")
    ModData.request(DICE_SYSTEM_MOD_STRING)
    DICE_CLIENT_MOD_DATA = ModData.get(DICE_SYSTEM_MOD_STRING)

    if DICE_CLIENT_MOD_DATA == nil then
        DICE_CLIENT_MOD_DATA = {}
    --else
        --print("Found DICE_SYSTEM global mod data, sent it to client")
        --print(DICE_CLIENT_MOD_DATA)
    end
end

Events.OnConnected.Add(OnConnected)


local function copyTable(tableA, tableB)
    if not tableA or not tableB then
        return
    end
    for key, value in pairs(tableB) do
        tableA[key] = value
    end
    for key, _ in pairs(tableA) do
        if not tableB[key] then
            tableA[key] = nil
        end
    end
end




---This is a fairly aggressive way to sync the moddata table. Use it sparingly
---@param username any
local function SyncPlayerTable(username)
    sendClientCommand(getPlayer(), DICE_SYSTEM_MOD_STRING, "UpdatePlayerStats",
        { data = DICE_CLIENT_MOD_DATA[username], username = username })
end

local function ReceiveGlobalModData(key, data)
    --print("Received global mod data")
    if key == DICE_SYSTEM_MOD_STRING then
        --Creating a deep copy of recieved data and storing it in local store CLIENT_GLOBALMODDATA table
        copyTable(DICE_CLIENT_MOD_DATA, data)
    end

    --Update global mod data with local table (from global_mod_data.bin)
    ModData.add(DICE_SYSTEM_MOD_STRING, DICE_CLIENT_MOD_DATA)
end

Events.OnReceiveGlobalModData.Add(ReceiveGlobalModData)

--------------------------------

---ok
---@param username string
---@return PlayerHandler
function PlayerHandler:instantiate(username)

    if PlayerHandler.handlers[username] then
        -- TODO This is overkill, we should request ONLY the data we need from the server, not the whole table
        --ModData.request(DICE_SYSTEM_MOD_STRING)
        --DICE_CLIENT_MOD_DATA = ModData.get(DICE_SYSTEM_MOD_STRING)
        return PlayerHandler.handlers[username]
    end


    local o = {}
    setmetatable(o, self)

    o.username = username
    o.diceData = DICE_CLIENT_MOD_DATA[username]

    PlayerHandler.handlers[username] = o
    return o
end

function PlayerHandler:checkDiceDataValidity()
    if DICE_CLIENT_MOD_DATA and self.username and DICE_CLIENT_MOD_DATA[self.username] then
        self.diceData = DICE_CLIENT_MOD_DATA[self.username]
        return true
    end

    return false
end

--*  Skills handling *--

---Get the skill points + bonus skill points
---@param skill string
---@return number
function PlayerHandler:getFullSkillPoints(skill)
    local points = self.diceData.skills[skill]
    local bonusPoints = self.diceData.skillsBonus[skill]

    return points + bonusPoints
end

---Get the amount of points for a specific skill.
---@param skill string
---@return number
function PlayerHandler:getSkillPoints(skill)
    if self.diceData == nil then
        --print("DiceSystem: modData is nil, can't return skill point value")
        return -1
    end

    local points = self.diceData.skills[skill]
    if points ~= nil then
        return points
    else
        return -1
    end
end

---Get the amount of bonus points for a specific skill.
---@param skill string
---@return number
function PlayerHandler:getBonusSkillPoints(skill)
    if self.diceData == nil then
        --print("DiceSystem: modData is nil, can't return skill point value")
        return -1
    end

    local points = self.diceData.skillsBonus[skill]
    if points ~= nil then
        return points
    else
        return -1
    end
end

---Increment a specific skillpoint
---@param skill string
---@return boolean
function PlayerHandler:incrementSkillPoint(skill)
    local result = false

    if self.diceData.allocatedPoints < 20 and self.diceData.skills[skill] < 5 then
        self.diceData.skills[skill] = self.diceData.skills[skill] + 1
        self.diceData.allocatedPoints = self.diceData.allocatedPoints + 1
        result = true
    end

    return result
end

---Decrement a specific skillpoint
---@param skill string
---@return boolean
function PlayerHandler:decrementSkillPoint(skill)
    local result = false
    if self.diceData.skills[skill] > 0 then
        self.diceData.skills[skill] = self.diceData.skills[skill] - 1
        self.diceData.allocatedPoints = self.diceData.allocatedPoints - 1
        result = true
    end

    return result
end

---Add or subtract to any skill point for this user
---@param skill any
---@param operation any
---@return boolean
function PlayerHandler:handleSkillPoint(skill, operation)
    local result = false

    if operation == "+" then
        result = self:incrementSkillPoint(skill)
    elseif operation == "-" then
        result = self:decrementSkillPoint(skill)
    end

    -- In case of failure, just return.
    if not result then return false end

    --* Special cases

    -- Movement Bonus scales in Endurance
    if skill == 'Endurance' then
        local actualPoints = self:getSkillPoints(skill)
        local bonusPoints = self:getBonusSkillPoints(skill)
        self:applyMovementBonus(actualPoints, bonusPoints)
    end
    return result
end

function PlayerHandler:getAllocatedSkillPoints()
    if self.diceData == nil then
        --print("DiceSystem: modData is nil, can't return skill point value")
        return -1
    end

    local allocatedPoints = self.diceData.allocatedPoints
    if allocatedPoints ~= nil then return allocatedPoints else return -1 end
end

--* Occupations *--

---Returns the player's occupation
---@return string
function PlayerHandler:getOccupation()
    -- This is used in the prerender for our special combobox. We'll add a bit of added logic to be sure that it doesn't break
    if DICE_CLIENT_MOD_DATA and self.username and DICE_CLIENT_MOD_DATA[self.username] then
        return DICE_CLIENT_MOD_DATA[self.username].occupation
    end

    return ""
end

---Set an occupation and its related bonuses
---@param occupation string
function PlayerHandler:setOccupation(occupation)
    --print("Setting occupation")
    --print(PlayerStatsHandler.username)
    if self.diceData == nil then return end

    --print("Setting occupation => " .. occupation)
    self.diceData.occupation = occupation
    local bonusData = PLAYER_DICE_VALUES.OCCUPATIONS_BONUS[occupation]

    -- Reset diceData.skillBonus
    for k, _ in pairs(self.diceData.skillsBonus) do
        self.diceData.skillsBonus[k] = 0
    end

    for key, bonus in pairs(bonusData) do
        self.diceData.skillsBonus[key] = bonus
    end
end

--* Status Effect *--

function PlayerHandler:toggleStatusEffectValue(statusEffect)
    -- Add a check in the UI to make it clear that we have selected them or something
    if self.diceData.statusEffects[statusEffect] ~= nil then
        self.diceData.statusEffects[statusEffect] = not self.diceData.statusEffects[statusEffect]
    end

    -- We need to force set an update since this is gonna be visible to all players!
    local isActive = self.diceData.statusEffects[statusEffect]
    local pl = getPlayerFromUsername(self.username)
    local userID = nil
    if pl then
        userID = pl:getOnlineID()
    end

    sendClientCommand(DICE_SYSTEM_MOD_STRING, 'UpdateStatusEffect', {username = self.username, userID = userID, statusEffect = statusEffect, isActive = isActive })
end

function PlayerHandler:getStatusEffectValue(status)
    local val = DICE_CLIENT_MOD_DATA[self.username].statusEffects[status]
    --print("Status: " .. status .. ",value: " .. tostring(val))
    return val
end

--* Health *--

---Returns current health
---@return number
function PlayerHandler:getCurrentHealth()
    if DICE_CLIENT_MOD_DATA and self.username and DICE_CLIENT_MOD_DATA[self.username] then
        return DICE_CLIENT_MOD_DATA[self.username].currentHealth
    end

    return -1
end

---Returns max health
---@return number
function PlayerHandler:getMaxHealth()
    if DICE_CLIENT_MOD_DATA and self.username and DICE_CLIENT_MOD_DATA[self.username] then
        return DICE_CLIENT_MOD_DATA[self.username].maxHealth
    end

    return -1
end

---Increments the current health
---@return boolean
function PlayerHandler:incrementCurrentHealth()
    if self.diceData.currentHealth < self.diceData.maxHealth then
        self.diceData.currentHealth = self.diceData.currentHealth + 1
        return true
    end

    return false
end

---Decrement the health
---@return boolean
function PlayerHandler:decrementCurrentHealth()
    if self.diceData.currentHealth > 0 then
        self.diceData.currentHealth = self.diceData.currentHealth - 1
        return true
    end

    return false
end

---Modifies current health
---@param operation char
function PlayerHandler:handleCurrentHealth(operation)
    local result = false
    if operation == "+" then
        result = self:incrementCurrentHealth()
    elseif operation == "-" then
        result = self:decrementCurrentHealth()
    end

    if result and DICE_CLIENT_MOD_DATA[self.username].isInitialized then
        local currentHealth = self:getCurrentHealth()
        sendClientCommand(DICE_SYSTEM_MOD_STRING, 'UpdateCurrentHealth', {currentHealth = currentHealth, username = self.username})
    end
end

--* Movement *--

function PlayerHandler:incrementCurrentMovement()
    if self.diceData.currentMovement < self.diceData.maxMovement + self.diceData.movementBonus then
        self.diceData.currentMovement = self.diceData.currentMovement + 1
        return true
    end

    return false
end

function PlayerHandler:decrementCurrentMovement()
    if self.diceData.currentMovement > 0 then
        self.diceData.currentMovement = self.diceData.currentMovement - 1
        return true
    end
    return false
end

function PlayerHandler:handleCurrentMovement(operation)
    local result = false
    if operation == "+" then
        result = self:incrementCurrentMovement()
    elseif operation == "-" then
        result = self:decrementCurrentMovement()
    end

    if result and DICE_CLIENT_MOD_DATA[self.username].isInitialized then
        sendClientCommand(DICE_SYSTEM_MOD_STRING, 'UpdateCurrentMovement', {currentMovement = self:getCurrentMovement(), username = self.username})
    end
end

---Returns current movmenet
---@return number
function PlayerHandler:getCurrentMovement()
    if self:checkDiceDataValidity() then
        return DICE_CLIENT_MOD_DATA[self.username].currentMovement
    end

    return -1
end

function PlayerHandler:setCurrentMovement(movement)
    DICE_CLIENT_MOD_DATA[self.username].currentMovement = movement
end

---Returns the max movement value
---@return number
function PlayerHandler:getMaxMovement()
    if self:checkDiceDataValidity() then
        return DICE_CLIENT_MOD_DATA[self.username].maxMovement
    end

    return -1
end

---comment
---@param endurancePoints number
---@param enduranceBonusPoints number
function PlayerHandler:applyMovementBonus(endurancePoints, enduranceBonusPoints)
    local movBonus = math.floor((endurancePoints + enduranceBonusPoints) / 2)
    DICE_CLIENT_MOD_DATA[self.username].movementBonus = movBonus

end

function PlayerHandler:setMovementBonus(endurancePoints)
    local addedBonus = math.floor(endurancePoints / 2)
    DICE_CLIENT_MOD_DATA[self.username].movementBonus = addedBonus
end

function PlayerHandler:getMovementBonus()
    if self:checkDiceDataValidity() then
        return DICE_CLIENT_MOD_DATA[self.username].movementBonus
    end

    return -1
end

function PlayerHandler:setMaxMovement(maxMov)
    DICE_CLIENT_MOD_DATA[self.username].maxMovement = maxMov
    local movBonus = self:getMovementBonus()

    if self:getCurrentMovement() > maxMov + movBonus then
        DICE_CLIENT_MOD_DATA[self.username].currentMovement = maxMov + movBonus
    end
end


--* Armor Class *--

--- Returns the current value of armor bonus
---@return number
function PlayerHandler:getArmorClass()
    if self:checkDiceDataValidity() then
        local resolvePoints = DICE_CLIENT_MOD_DATA[self.username].skills["Resolve"]
        local resolveBonusPoints = DICE_CLIENT_MOD_DATA[self.username].skillsBonus["Resolve"]

        local armorClass = 8 + resolvePoints + resolveBonusPoints
        return armorClass
    end

    return -1
end

-----------------------------------

--* Initialization *--

--- Creates a new ModData for a player
---@param force boolean Force initializiation for the current player
function PlayerHandler:initModData(force)

    --print("[DiceSystem] Initializing!")

    if self.username == nil then
        self.username = getPlayer():getUsername()
    end
    -- This should happen only from that specific player, not an admin
    if (DICE_CLIENT_MOD_DATA ~= nil and DICE_CLIENT_MOD_DATA[self.username] == nil) or force then
        --print("[DiceSystem] Initializing new player dice data")
        local tempTable = {}
        tempTable = {
            isInitialized = false,
            occupation = "",
            statusEffects = {},

            currentHealth = PLAYER_DICE_VALUES.DEFAULT_HEALTH,
            maxHealth = PLAYER_DICE_VALUES.DEFAULT_HEALTH,

            currentMovement = PLAYER_DICE_VALUES.DEFAULT_MOVEMENT,
            maxMovement = PLAYER_DICE_VALUES.DEFAULT_MOVEMENT,
            movementBonus = 0,

            allocatedPoints = 0,

            skills = {},
            skillsBonus = {}
        }

        -- Setup status effects
        for i = 1, #PLAYER_DICE_VALUES.STATUS_EFFECTS do
            local x = PLAYER_DICE_VALUES.STATUS_EFFECTS[i]
            tempTable.statusEffects[x] = false
        end

        -- Setup skills
        for i = 1, #PLAYER_DICE_VALUES.SKILLS do
            local x = PLAYER_DICE_VALUES.SKILLS[i]
            tempTable.skills[x] = 0
            tempTable.skillsBonus[x] = 0
        end


        --PlayerStatsHandler.CalcualteArmorClass(getPlayer())

        DICE_CLIENT_MOD_DATA[self.username] = {}
        copyTable(DICE_CLIENT_MOD_DATA[self.username], tempTable)

        -- Sync it now
        SyncPlayerTable(self.username)
        print("DiceSystem: initialized player")
    elseif DICE_CLIENT_MOD_DATA[self.username] == nil then
        error("DiceSystem: Global mod data is broken")
    end
end

---Set if player has finished their setup via the UI
---@param isInitialized boolean
function PlayerHandler:setIsInitialized(isInitialized)
    -- Syncs it with server
    DICE_CLIENT_MOD_DATA[self.username].isInitialized = isInitialized

    -- Maybe the unique case where this is valid
    if isInitialized then
        SyncPlayerTable(self.username)
    end
end

function PlayerHandler:isPlayerInitialized()
    if DICE_CLIENT_MOD_DATA[self.username] == nil then
        --error("Couldn't find player dice data!")
        return
    end

    local isInit = DICE_CLIENT_MOD_DATA[self.username].isInitialized

    if isInit == nil then
        return false
    end

    return isInit
end

---------------

-- Setup at startup
Events.OnGameStart.Add(function()
    local handler = PlayerHandler:instantiate(getPlayer():getUsername())
    handler:initModData(false)

end)



return PlayerHandler
