-- TODO If you are setting your stats and hover somebody that has already set their stats, your stats are gonna die :(

-- Caching stuff
local playerBase = __classmetatables[IsoPlayer.class].__index
local getNum = playerBase.getPlayerNum
local heartIco = getTexture("media/ui/dnd_heart.png") -- Document icons created by Freepik - Flaticon - Document
local armorIco = getTexture("media/ui/dnd_armor.png")

local PlayerHandler = require("DiceSystem_PlayerHandler")
local CommonUI = require("UI/DiceSystem_CommonUI")

-----------------

--- Constants
-- Line at the start is necessary to let this game place the text in the correct position, at the center of the box
local B_HEALTH_STR = "<CENTRE> <SIZE:large> <RGB:0,1,0> %d/%d"
local B_ARMORCLASS_STR = "<CENTRE> <SIZE:large> <RGB:1,0,0> %d"

------------------

HoverUI = ISCollapsableWindow:derive("HoverUI")
HoverUI.openMenus = {}

---comment
---@param pl IsoPlayer
---@param username string Just the username of the player, since we've already referenced it before
function HoverUI.Open(pl, username)
    local width = 300 * CommonUI.FONT_SCALE
    local height = 200 * CommonUI.FONT_SCALE

    local plNum = getNum(pl)
    local plX = pl:getX()
    local plY = pl:getY()
    local plZ = pl:getZ()

    --TODO check if there's space, if not, switch to the left or bottom or up or whatever
    local x = isoToScreenX(plNum, plX, plY, plZ) * 1.1
    local y = isoToScreenY(plNum, plX, plY, plZ) * 0.7

    ModData.request(DICE_SYSTEM_MOD_STRING)
    local handler = PlayerHandler:instantiate(username)
    if handler:isPlayerInitialized() then

        -- Re request
        local userID = pl:getOnlineID()
        sendClientCommand(DICE_SYSTEM_MOD_STRING, 'RequestUpdatedStatusEffects',
            { username = username, userID = userID })

        HoverUI.openMenus[username] = HoverUI:new(x, y, width, height, pl, handler)
        HoverUI.openMenus[username]:initialise()
        HoverUI.openMenus[username]:bringToTop()
    end

end

function HoverUI.Close(username)
    HoverUI.openMenus[username]:close()
end

--************************************--

function HoverUI:new(x, y, width, height, pl, playerHandler)
    local o = {}
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.width = width
    o.height = height
    o.resizable = false
    o.variableColor = { r = 0.9, g = 0.55, b = 0.1, a = 1 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    o.moveWithMouse = true
    o.isOpening = true

    o.pl = pl
    o.playerHandler = playerHandler

    return o
end

--************************************--
---Initialization
function HoverUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:addToUIManager()
end

function HoverUI:createChildren()
    ISCollapsableWindow.createChildren(self)
	local yOffset = self:titleBarHeight() + 10
    local plDescriptor = self.pl:getDescriptor()
    local playerName = DiceSystem_Common.GetForenameWithoutTabs(plDescriptor) -- .. " " .. DiceSystem_Common.GetSurnameWithoutBio(plDescriptor)

    -- TOP PANEL

    --* Name Label *--
    CommonUI.AddCenteredTextLabel(self, "nameLabel", playerName, yOffset)
    yOffset = yOffset + 25

    --* Status Effects Panel *--
    local labelStatusEffectsHeight = 25 * (CommonUI.FONT_SCALE + 0.5)
    CommonUI.AddStatusEffectsPanel(self, labelStatusEffectsHeight, yOffset)

    -----------------

    local xOffset = 10
    self.frameSize = self.width / 3.5

    self.panelBottom = ISPanel:new(0, self.height/2.5, self.width, self.height - self.height/2.5)
    self.panelBottom:setAlwaysOnTop(false)
    self.panelBottom:initialise()
    self:addChild(self.panelBottom)

    local xCenter = self.panelBottom:getWidth() / 2
    local yPanels = ((self.panelBottom:getHeight() - self.frameSize) / 2) + 10  -- PADDING of 10
    local xHealthPanel = xCenter - self.frameSize - xOffset
    local xArmorPanel = xCenter + xOffset + 1                                         -- For some fucking reason there's a missing pixel, I hate this game

    CommonUI.AddPanel(self.panelBottom, "panelHealth", self.frameSize, self.frameSize, xHealthPanel, yPanels)
    CommonUI.AddPanel(self.panelBottom, "panelArmorClass", self.frameSize, self.frameSize, xArmorPanel, yPanels)


    self.panelBottom.panelHealth.marginTop = 0
    self.panelBottom.panelHealth.marginBottom = 0
    self.panelBottom.panelHealth.marginLeft = 0
    self.panelBottom.panelHealth.marginRight = 0
    self.panelBottom.panelHealth.background = true
    self.panelBottom.panelHealth.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.panelBottom.panelHealth.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }

    self.panelBottom.panelArmorClass.marginTop = 0
    self.panelBottom.panelArmorClass.marginBottom = 0
    self.panelBottom.panelArmorClass.marginLeft = 0
    self.panelBottom.panelArmorClass.marginRight = 0
    self.panelBottom.panelArmorClass.background = true
    self.panelBottom.panelArmorClass.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.panelBottom.panelArmorClass.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
end

function HoverUI:update()
    ISCollapsableWindow.update(self)
    CommonUI.UpdateStatusEffectsText(self, self.pl:getUsername())
end

function HoverUI:prerender()
    ISCollapsableWindow.prerender(self)

    local healthText = getText("IGUI_MiniUI_Health")
    local armorClassText = getText("IGUI_MiniUI_ArmorClass")

    local yLabel = self.panelBottom.panelHealth:getY() - getTextManager():MeasureStringY(UIFont.Large, healthText)                                                                                                                -- Additional 1 offset
    local xHealth = (self.panelBottom.panelHealth:getX() + self.panelBottom.panelHealth:getWidth() / 2) - getTextManager():MeasureStringX(UIFont.Large, healthText) / 2
    self.panelBottom:drawText(healthText, xHealth, yLabel, 1, 1, 1, 1, UIFont.Large)

    local xArmorClass = (self.panelBottom.panelArmorClass:getX() + self.panelBottom.panelArmorClass:getWidth() / 2) - getTextManager():MeasureStringX(UIFont.Large, armorClassText) / 2
    self.panelBottom:drawText(armorClassText, xArmorClass, yLabel, 1, 1, 1, 1, UIFont.Large)

    local iconSize = self.frameSize


    self.panelBottom.panelHealth:drawTextureScaled(heartIco, 0, 0, iconSize, iconSize, 0.2, 1, 1, 1)
    self.panelBottom.panelArmorClass:drawTextureScaled(armorIco, 0, 0, iconSize, iconSize, 0.2, 1, 1, 1)
end

function HoverUI:render()
    ISCollapsableWindow.render(self)

    if self.isOpening then
        self.backgroundColor.a = self.backgroundColor.a + 0.1 -- Horrendous
        if self.backgroundColor.a >= 1 then
            self.isOpening = false
        end
    end

    --* Health *--
    local healthStr = string.format(B_HEALTH_STR, self.playerHandler:getCurrentHealth(),
        self.playerHandler:getMaxHealth())
    self.panelBottom.panelHealth.marginTop = self.panelBottom.panelHealth:getHeight() / 2 -
    getTextManager():MeasureStringY(UIFont.Large, healthStr) / 2
    self.panelBottom.panelHealth:setText(healthStr)
    self.panelBottom.panelHealth.textDirty = true

    --* Armor Class *--
    local armorStr = string.format(B_ARMORCLASS_STR, self.playerHandler:getArmorClass())
    self.panelBottom.panelArmorClass.marginTop = self.panelBottom.panelArmorClass:getHeight() / 2 -
    getTextManager():MeasureStringY(UIFont.Large, armorStr) / 2
    self.panelBottom.panelArmorClass:setText(armorStr)
    self.panelBottom.panelArmorClass.textDirty = true
end

function HoverUI:close()
    HoverUI.openMenus[self.pl:getUsername()] = nil
    local tableIndex = self.pl:getUsername() .. tostring(self)
    CommonUI.RemoveCachedStatusEffectsText(tableIndex)
    ISCollapsableWindow.close(self)
end

--------------------------------------

local function FillHoverMenuOptions(player, context, worldobjects, test)
    local subMenu
    local obj = worldobjects[1]
    local clickedSq = obj:getSquare()
    local playerObj = getSpecificPlayer(player)
    local currentPlHandler = PlayerHandler:instantiate(playerObj:getUsername())
    if currentPlHandler:isPlayerInitialized() == false then return end
    if clickedSq == nil then return end

    for x = clickedSq:getX() - 1, clickedSq:getX() + 1 do
        for y = clickedSq:getY() - 1, clickedSq:getY() + 1 do
            local sq = getCell():getGridSquare(x, y, clickedSq:getZ())
            if sq then
                for i = 0, sq:getMovingObjects():size() - 1 do
                    local o = sq:getMovingObjects():get(i)
                    if instanceof(o, "IsoPlayer") and (not o:isInvisible() or isAdmin()) then
                        local username = o:getUsername()
                        if subMenu == nil then
                            local optionHoverMenu = context:addOption("Dice Mini Menu", worldobjects, nil)
                            subMenu = ISContextMenu:getNew(context)
                            context:addSubMenu(optionHoverMenu, subMenu)
                        end

                        local plDescriptor = o:getDescriptor()
                        local playerName = DiceSystem_Common.GetForenameWithoutTabs(plDescriptor)
                        if HoverUI.openMenus[username] == nil then
                            subMenu:addOption("Open Menu for " .. playerName, o, HoverUI.Open, username)
                        else
                            subMenu:addOption("Close Menu for " .. playerName, username, HoverUI.Close)
                        end
                    end
                end
            end
        end
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(FillHoverMenuOptions)
