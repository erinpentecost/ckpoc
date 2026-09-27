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
local MOD_NAME          = require("scripts.CryptKeeper.ns")
local const = require("scripts.CryptKeeper.const")
local storage  = require('openmw.storage')
local world    = require('openmw.world')
local async    = require('openmw.async')
local types    = require('openmw.types')
local core    = require('openmw.core')
local aux_util = require('openmw_aux.util')
local settings = require("scripts.CryptKeeper.settings.settings")
local interfaces = require('openmw.interfaces')
local vfs = require('openmw.vfs')


---@class Persisted
---@field urnRecords {[string]:UrnItemData}

---@type Persisted
local persist = {
    urnRecords = {},
}
local function onLoad(data)
    if data then
        persist = data
    end
end
local function onSave()
    return persist
end

--- sometimes meshes/o/xcontain_urn_05.nif, but contain_urn_05.nif exists too
local urnMeshPath = "meshes/o/contain_urn_04.nif"
if vfs.fileExists("meshes/o/xcontain_urn_04.nif") then
    urnMeshPath = "meshes/o/xcontain_urn_04.nif"
end
local urnItemScriptPath = string.lower("scripts\\" .. MOD_NAME .. "\\urn.lua")
local urnIconPath = string.lower("icons\\" .. MOD_NAME .. "\\urn.tga")

---@class onQuestStartData
---@field player table
---@field quest Quest

---@param data onQuestStartData
local function onQuestStart(data)
    settings.debugPrint("onQuestStart: " .. aux_util.deepToString(data, 5))
    --- generate the urn and give it to the player

    --- MiscellaneousRecord
    local itemRecordDraft = types.Miscellaneous.createRecordDraft({
        icon = urnIconPath,
        isKey = false,
        model = urnMeshPath,
        name = data.quest.urnName,
        value = 0,
        weight = 40,
    })
    local itemRecord = world.createRecord(itemRecordDraft)


    local containerRecordDraft = types.Container.createRecordDraft({
        isOrganic = false,
        isRespawning = false,
        model = urnMeshPath,
        name = data.quest.urnName,
        --- this is capacity now.
        --- make it big so people can use a tomb as a home base comfortably
        weight = 500,
    })

    local containerRecord = world.createRecord(containerRecordDraft)

    local recordInstance = world.createObject(itemRecord.id, 1)
    settings.debugPrint("made new urn record (" .. tostring(itemRecord.id) .. ") - " .. data.quest.urnName)
    if not recordInstance:hasScript(urnItemScriptPath) then
        recordInstance:addScript(urnItemScriptPath, {
            quest = data.quest,
            itemRecordId = itemRecord.id,
            containerRecordId = containerRecord.id
        })
    end
    recordInstance:moveInto(data.player)

    local vars = world.mwscript.getGlobalVariables(data.player)
    vars[const.URN_DELIVERY_ACTIVE_GVAR] = 1
    vars[const.HAS_URN_GVAR] = 1
    --- send event to player so we can start "holding" the urn
    ---@type UrnItemData
    local payload = {
        quest = data.quest,
        --urn = recordInstance,
        --cell = data.player.cell.id,
        --player = data.player,
        itemRecordId = itemRecord.id,
        containerRecordId = containerRecord.id
    }
    persist.urnRecords[data.quest.id] = payload
    data.player:sendEvent(MOD_NAME .. "onUrnInfo", persist.urnRecords)
end

local function onPlayerAdded(player)
    player:sendEvent(MOD_NAME .. "onUrnInfo", persist.urnRecords)
end

---@param data UrnEventData
local function onUrnPlacedDone(data)
    settings.debugPrint("placed urn " .. data.quest.id)
    --- replace item with container

    local recordInstance = world.createObject(data.containerRecordId, 1)
    recordInstance:teleport(data.cell, data.urn.position, {
        rotation = data.urn.rotation
    })
    data.urn:remove()

    local vars = world.mwscript.getGlobalVariables(data.player)
    vars[const.URNS_DELIVERED_GVAR] = vars[const.URNS_DELIVERED_GVAR] + 1
    vars[const.URN_DELIVERY_ACTIVE_GVAR] = 0
    vars[const.HAS_URN_GVAR] = 0
end

---@param data UrnEventData
local function onUrnDropped(data)
    settings.debugPrint("urn dropped")
    local vars = world.mwscript.getGlobalVariables(data.player)
    vars[const.HAS_URN_GVAR] = 0
end

---@param data UrnEventData
local function onUrnPickedUp(data)
    settings.debugPrint("urn picked up")
    local vars = world.mwscript.getGlobalVariables(data.player)
    vars[const.HAS_URN_GVAR] = 1
end

return {
    eventHandlers = {
        [MOD_NAME .. "onQuestStart"] = onQuestStart,
        [MOD_NAME .. "onUrnPlacedDone"] = onUrnPlacedDone,
        [MOD_NAME .. "onUrnDropped"] = onUrnDropped,
        [MOD_NAME .. "onUrnPickedUp"] = onUrnPickedUp,
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onPlayerAdded = onPlayerAdded,
    },
}
