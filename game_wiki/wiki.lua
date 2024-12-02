local api = "https://wiki.rookgaard.pl/api/"
local config = {
    api = {
        motd = function () return api .. 'bonus/monster' end,
        monster = function (name) return api .. 'monster/' .. name .. '/fixera' end,
        available = function () return api .. 'available' end
    }
}

local database = {
    items = {},
    npcs = {},
    monsters = {},
    monsterOfTheDay = nil
}

-- Zmienne globalne
local window = nil
local wikiButton = nil

local itemDataTab = nil
local npcDataTab = nil
local mobDataTab = nil
local dataPanel = nil

function init()
    window = g_ui.displayUI('wiki')
    window:setVisible(false)
    wikiButton = modules.client_topmenu.addRightGameToggleButton('wikiButton', tr('Wiki'), '/images/topbuttons/wiki', toggleWindow, false, 8)
    motd()
    setupTabs()
    fetchAvailableItems()
    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })
end

function onGameEnd()
    if wikiButton then
        wikiButton:hide()
    end
    if window then
        window:hide()
    end
end

function onGameStart()
    if wikiButton then
        wikiButton:setOn(false)
        wikiButton:show()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })

    if window then
        window:destroy()
        window = nil
    end

    if wikiButton then
        wikiButton:destroy()
        wikiButton = nil
    end

    database = {}
end

function toggleWindow()
    if not g_game.isOnline() or not wikiButton or not window then
        return
    end

    if wikiButton:isOn() then
        window:setVisible(false)
        wikiButton:setOn(false)
    else
        window:setVisible(true)
        wikiButton:setOn(true)

    end
end

function clearContent()
    dataPanel:destroyChildren()
end

-- Monster of The Day
function motd()
    if not window then
        return
    end

    if database.monsterOfTheDay then
        return
    end

    local function parseMonsterData(response)
        if not response then
            return
        end

        database.monsterOfTheDay = json.decode(response)
        window.motdPanel.motdCreature:setOutfit(database.monsterOfTheDay.look)
    end

    local function parseMonsterName(response)
        if not response then
            return
        end
        
        database.monsterOfTheDay = {
            name = response:gsub('"', "")
        }
        window.motdPanel.motdName:setText(database.monsterOfTheDay.name)
        HTTP.get(config.api.monster(database.monsterOfTheDay.name), parseMonsterData)
    end

    HTTP.get(config.api.motd(), parseMonsterName)
end

-- Tabs setup
function setupTabs()
    itemDataTab = window:getChildById('itemData')
    npcDataTab = window:getChildById('npcData')
    mobDataTab = window:getChildById('mobData')
    dataPanel = window:getChildById('dataPanel')

    local function onTabChange(selectedTab)
        itemDataTab:setOn(selectedTab == itemDataTab)
        npcDataTab:setOn(selectedTab == npcDataTab)
        mobDataTab:setOn(selectedTab == mobDataTab)
        clearContent()
        
        if selectedTab == itemDataTab then
            fetchAvailableItems()
        elseif selectedTab == npcDataTab then
            fetchAvailableNpcs()
        elseif selectedTab == mobDataTab then
            fetchAvailableMobs()
        end
    end

    itemDataTab.onClick = function() onTabChange(itemDataTab) end
    npcDataTab.onClick = function() onTabChange(npcDataTab) end
    mobDataTab.onClick = function() onTabChange(mobDataTab) end
end

-- Item Data 
function fetchAvailableItems()
    local function parseAvailableItems(response)
        if not response then
            return
        end

        local data = json.decode(response)
        local items = data.ITEMS


        if items and #items > 0 then

            for _, itemList in ipairs(items) do
                for _, item in ipairs(itemList) do

                    local entry = g_ui.createWidget('WikiItemBox', window.dataPanel)
                    entry.itemId:setItemId(item.clientId)
                    entry.itemName:setText(item.name)
                end
            end
        end
    end

    HTTP.get(config.api.available(), parseAvailableItems)
end

-- Npcs Data
function fetchAvailableNpcs()
    local function parseAvailableNpcs(response)
        if not response then
            return
        end

        local data = json.decode(response)
        local npcs = data.NPCS


        if npcs and #npcs > 0 then

            for _, npcList in ipairs(npcs) do
                for _, npc in ipairs(npcList) do

                    local entry = g_ui.createWidget('WikiNpcsBox', window.dataPanel)
                    entry.npcLook:setOutfit(npc.look)
                    entry.npcName:setText(npc.name)
                end
            end
        end
    end

    HTTP.get(config.api.available(), parseAvailableNpcs)
end

-- Mob Data
function fetchAvailableMobs()
    local function parseAvailableMobs(response)
        if not response then
            return
        end

        local data = json.decode(response)
        local mobs = data.MONSTERS


        if mobs and #mobs > 0 then

            for _, mobList in ipairs(mobs) do
                for _, mob in ipairs(mobList) do

                    local entry = g_ui.createWidget('WikiMobBox', window.dataPanel)
                    entry.mobLook:setOutfit(mob.look)
                    entry.mobName:setText(mob.name)
                end
            end
        end
    end

    HTTP.get(config.api.available(), parseAvailableMobs)
end
