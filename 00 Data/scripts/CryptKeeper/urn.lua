--[[
CryptKeeper for OpenMW.
Copyright (C) 2026 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local core                  = require('openmw.core')
local types                 = require('openmw.types')
local pself                 = require('openmw.self')
local async                 = require('openmw.async')
local nearby = require('openmw.nearby')
local MOD_NAME              = require("scripts.CryptKeeper.ns")
local interfaces = require('openmw.interfaces')
local aux_util = require('openmw_aux.util')

---@class UrnItemData
---@field quest Quest?
---@field itemRecordId string?
---@field containerRecordId string?

---@type UrnItemData
local persist    = {
    ---@type Quest?
    quest = nil,
    ---@type string?
    itemRecordId = nil,
    ---@type string?
    containerRecordId = nil,
}

---@class UrnEventData : UrnItemData
---@field urn table
---@field player table
---@field cell string

---@param data UrnItemData
local function onInit(data)
    if data ~= nil then
        persist = data
    end
    print("Urn onInit triggered. persist data: " .. aux_util.deepToString(persist, 3))
end

---@param data UrnItemData
local function onLoad(data)
    if data ~= nil then
        persist = data
    end
    print("Urn onLoad triggered. persist data: " .. aux_util.deepToString(persist, 3))
end

local function onSave()
    print("Urn onSave triggered. persist data: ".. aux_util.deepToString(persist, 3))
    return persist
end

local function getClosestPlayer()
    local closestPlayer
    local closestDistanceSquared = math.huge

    for _, player in ipairs(nearby.players) do
        local d2 = (player.position - pself.object.position):length2()
        if d2 < closestDistanceSquared then
            closestPlayer = player
            closestDistanceSquared = d2
        end
    end

    return closestPlayer
end

local player = nil
local cell = nil

local function onActive()
    --- this happens when the urn is placed down.
    print("Urn onActive triggered. persist data: " .. aux_util.deepToString(persist, 3))
    --- if we are in destcell, we can increment the quest stage..
    --- but I don't want them to pick it up, afteward.
    --- but I DO want them to be able to move it around after if they have OCD
    player = getClosestPlayer()
    cell = pself.cell

    if player == nil then
        error("no player for urn")
        return
    end
    if cell == nil then
        error("no cell for urn")
        return
    end

    if cell.id == persist.quest.destCell then
        --- yay, the player put the urn in the right cell

        ---@type UrnEventData
        local payload = {
            quest = persist.quest,
            urn = pself.object,
            cell = cell.id,
            player = player,
            itemRecordId = persist.itemRecordId,
            containerRecordId = persist.containerRecordId
        }

        player:sendEvent(MOD_NAME .. "onUrnPlacedStart", payload)
        --core.sendGlobalEvent(MOD_NAME .. "onUrnPlacedStart", payload)
    end
end

--- this happens when the urn goes back into the player's inventory, too!
--- not just when unloaded from the world.
local function onInactive()
    print("onInactive")
    if player == nil then
        error("no player for urn")
        return
    end
    if cell == nil then
        error("no cell for urn")
        return
    end

    if pself.count == 0 then
        print("stack of 0")
        return
    end

    if player.cell:isInSameSpace(pself.object) then
        print("same world space")
        return
    end

    if cell and player and (cell.id == persist.quest.destCell) then
        --- ok, player is happy with the location.
        player:sendEvent(MOD_NAME .. "onUrnPlacedDone", { quest = persist.quest })
        core.sendGlobalEvent(MOD_NAME .. "onUrnPlacedDone", {
            quest = persist.quest,
            urn = pself.object,
            cell = cell.id,
        })
    end
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onActive = onActive,
    }
}
