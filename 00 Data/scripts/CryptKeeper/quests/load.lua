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
local MOD_NAME = require("scripts.CryptKeeper.ns")
local vfs      = require('openmw.vfs')
local markup     = require('openmw.markup')
local core   = require('openmw.core')
local settings = require("scripts.CryptKeeper.settings.settings")
local collection = require("scripts.CryptKeeper.collection")

---@class Quest
---@field id string this is the journal topic id
---@field disable boolean? if true, don't load it
---@field startStage number the start stage to 'activate' the quest. default 10.
---@field destCellEnterStage number? optional stage on cell enter. can be used for "oh no there are tomb raiders". should be before placeStage (like 39). this is just a notification.
---@field destCellClearedStage number? optional stage when all enemies in dest cell are dead. if this is present, then placeStage won't be set until the cell is cleared out. should be before placeStage (like 40).
---@field placeStage number the placement stage. this means they put the urn down. default 49. this should have an entry. this is just a notification. it will be set once all conditions (placed + optionall cleared) are met.
---@field placeCompleteStage number the post-placement success stage. this means they left the urn in the tomb. default 50. this should be an empty journal entry
---@field reportStage number the post-reported success stage. end stage. default 100.
---@field lostStage number if the player gives up or sells the urn. end stage. default 200.
---@field startCell string not used by anything really
---@field destCell string
---@field urnName string

---@type {[string]: Quest}
local quests    = {}

local function dialogueRecordInfoWithStage(infoRecords, stage)
    for _, rec in pairs(infoRecords) do
        if rec.questStage == stage then
            return rec
        end
    end
    return nil
end

local function load()
    local count = 0
    local function hasSuffix(str, suffix)
        if #suffix == 0 then return true end
        return str:sub(- #suffix) == suffix
    end

    ---@alias ErrMsg string

    ---@param v Quest
    ---@return Quest|ErrMsg
    local function loadQuest(v)
        local id = tostring(v.id or "unknown quest")
        if v.disable then
            return id..": disabled"
        end
        if v.startStage == nil then
            v.startStage = 10
        end
        if v.placeStage == nil then
            v.placeStage = 49
        end
        if v.placeCompleteStage == nil then
            v.placeCompleteStage = 50
        end
        if v.reportStage == nil then
            v.reportStage = 100
        end
        if v.lostStage == nil then
            v.lostStage = 200
        end
        if (v.destCellEnterStage == nil) == (v.destCellClearedStage) then
            return id..": destCellClearedStage and destCellEnterStage must both be set or unset, not mixed"
        end
        if v.destCellEnterStage and v.destCellEnterStage >= v.placeStage then
            return id..": destCellEnterStage must be < placeStage"
        end
        if v.destCellClearedStage and v.destCellClearedStage >= v.placeStage  then
            return id..": destCellClearedStage must be < placeStage"
        end
        v.id = v.id:lower()
        v.destCell = v.destCell:lower()
        v.startCell = v.startCell:lower()
        local journalRecord = core.dialogue.journal.records[v.id]
        if journalRecord == nil then
            return id..":  no dialogue journal record with id " .. tostring(v.id)
        end
        if dialogueRecordInfoWithStage(journalRecord.infos, v.startStage) == nil then
            return id..": missing start stage " .. tostring(v.startStage)
        end
        if dialogueRecordInfoWithStage(journalRecord.infos, v.placeStage) == nil then
            return id..":  missing place stage " .. tostring(v.placeStage)
        end
        if dialogueRecordInfoWithStage(journalRecord.infos, v.placeCompleteStage) == nil then
            return id..":  missing place complete stage " .. tostring(v.placeCompleteStage)
        end
        if dialogueRecordInfoWithStage(journalRecord.infos, v.reportStage) == nil then
            return id..":  missing report stage " .. tostring(v.reportStage)
        elseif not dialogueRecordInfoWithStage(journalRecord.infos, v.reportStage).isQuestFinished then
            return id..":  report stage " .. tostring(v.reportStage).. " is not marked as QuestFinished"
        end
        if dialogueRecordInfoWithStage(journalRecord.infos, v.lostStage) == nil then
            return id..":  missing lost stage " .. tostring(v.lostStage)
        elseif not dialogueRecordInfoWithStage(journalRecord.infos, v.lostStage).isQuestFinished then
            return id..":  lostStage stage " .. tostring(v.lostStage) .. " is not marked as QuestFinished"
        end
        return v
    end

    local function loadFile(fileName)
        local result = markup.loadYaml(fileName)
        for _, v in ipairs(result.quests) do
            ---@cast v Quest
            local parsed = loadQuest(v)
            if parsed then
                if type(parsed) == "string" then
                    print("Quest load ERROR: " .. parsed)
                else
                    quests[v.id] = v
                    count = count + 1
                end
            end
        end
    end


    for fileName in vfs.pathsWithPrefix("scripts\\" .. MOD_NAME .. "\\quests") do
        if hasSuffix(fileName:lower(), ".yaml") then
            loadFile(fileName)
        end
    end

    settings.debugPrint("Loaded " .. tostring(count) .. " quests.")
end

load()

return quests
