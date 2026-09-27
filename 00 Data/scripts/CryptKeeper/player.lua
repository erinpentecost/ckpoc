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
local settings   = require("scripts.CryptKeeper.settings.settings")
local allQuests  = require("scripts.CryptKeeper.quests.load")
local aux_util = require('openmw_aux.util')

---optionally use this if available
local FollowerDetectionUtil = interfaces.FollowerDetectionUtil

---@class QuestContainer
---@field metaData Quest
---@field playerQuest table this is a types.PLAYERQuest

---@type {[string]: QuestContainer}
local activeQuests = {}

local function updateActiveQuests()
    local quests = types.Player.quests(pself)

    for questId, quest in pairs(quests) do
        if allQuests[questId] then
            print("syncing "..tostring(questId)..": "..aux_util.deepToString(quest, 5))
            if (quest.started and not quest.finished) and (quest.stage >= allQuests[questId].startStage) and (quest.stage < allQuests[questId].placeStage) then
                activeQuests[questId] = {
                    metaData = allQuests[questId],
                    playerQuest = quest
                }
            end
        end
    end

    settings.debugPrint("activeQuests: " .. aux_util.deepToString(activeQuests, 5))
end

local function onQuestUpdate(questId, stage)
    if allQuests[questId] then
        settings.debugPrint("onQuestUpdate(" .. tostring(questId) .. ", " .. tostring(stage) .. ")")
        -- hey one of our tracked quests changed.
        -- let's re-sync everything
        updateActiveQuests()

        -- if this is the start of a new quest, give the player the urn
        if activeQuests[questId].metaData.startStage == activeQuests[questId].playerQuest.stage then
            core.sendGlobalEvent(MOD_NAME .. "onQuestStart", {
                player = pself.object,
                quest = allQuests[questId],
            })
        end
    end
end

local function isUndead(creature)
    return types.Creature.objectIsInstance(creature) and
    types.Creature.record(creature).type == types.Creature.TYPE.Undead
end

local function isBandit(actor)
    -- 30 is normal for friendly NPCs.
    -- chargen boat guard has 70!
    -- bandits have 90 and 0 disposition
    local fightStat = types.Actor.stats.ai.fight(actor).base
    if types.Creature.objectIsInstance(actor) then
        local startDisposition = types.NPC.getBaseDisposition(actor, pself)
        if fightStat >= 90 and startDisposition <= 40 then
            return true
        end
    end
    return fightStat >= 90
end

local function getEnemies()
    --- don't make this a hard dependency
    local followers = {}
    if FollowerDetectionUtil then
        followers = FollowerDetectionUtil.getFollowerList()
    end
    --- iterate nearby for all enemies
    local enemies = {}
    for _, actor in ipairs(nearby.actors) do
        if actor:isValid() and not types.Actor.isDead(actor) and not followers[actor.id] and not isUndead(actor) and isBandit(actor) then
            table.insert(actor)
        end
    end
    return enemies
end

---@type {[string]:UrnEventData}
local latestUrnData = {}
local currentQuestID = nil
local insideDestCell = false
local enemiesInCurrentDestCell = {}

local currentCellID = pself.cell.id
local function onCellLoaded()
    local lastCell = currentCellID
    currentCellID = pself.cell.id
    insideDestCell = false
    currentQuestID = nil
    --- did we enter a dest cell for an active quest?
    for _, quest in pairs(activeQuests) do
        settings.debugPrint("checking quest: " .. aux_util.deepToString(quest, 5))
        if quest.metaData.destCell == currentCellID then
            insideDestCell = true
            currentQuestID = quest.metaData.id
            -- we entered target cell!
            -- update the journal.
            if quest.metaData.destCellEnterStage ~= nil and quest.playerQuest.stage < quest.metaData.destCellEnterStage then
                quest.playerQuest:addJournalEntry(quest.metaData.destCellEnterStage, pself)
            end
            enemiesInCurrentDestCell = getEnemies()
            settings.debugPrint("Enemies in current cell: " .. tostring(#enemiesInCurrentDestCell))
        elseif (quest.metaData.destCell == lastCell) and (quest.playerQuest.stage == quest.metaData.placeStage) and latestUrnData[quest.metaData.id] then
            --- we just left the destination cell, and we previously placed the urn.
            --- if we don't have the urn in our inventory, then we'll advance quest stage
            --- and swap the urn with a container
            local inventory = types.Actor.inventory(pself)
            if inventory:countOf(latestUrnData[quest.metaData.id].itemRecordId) == 0 then
                settings.debugPrint("locking in urn placement")
                quest.playerQuest:addJournalEntry(quest.metaData.placeCompleteStage, pself)
                core.sendGlobalEvent(MOD_NAME .. "onUrnPlacedDone", latestUrnData[quest.metaData.id])
            end
        end
    end
    if not insideDestCell then
        enemiesInCurrentDestCell = {}
    end
end

local function onActive()
    onCellLoaded()
    updateActiveQuests()
end

local jitterSeed = 0
local function jitter(max_jitter)
    jitterSeed = jitterSeed + 1

    local x = jitterSeed * 12.9898
    local rand = x - math.floor(x)
    x = rand * 43758.5453
    rand = x - math.floor(x)

    return (rand * 2 - 1) * max_jitter
end

local LOOP_DELAY = 0.3
local updateDelay = LOOP_DELAY
local function onUpdate(dt)
    -- don't run this all the time
    if updateDelay > 0 then
        updateDelay = updateDelay - dt
        return
    end
    updateDelay = (LOOP_DELAY + jitter(LOOP_DELAY))/2
    --- check for cell change
    if pself.cell.id ~= currentCellID then
        onCellLoaded()
    end

    --- check if we killed all the enemies
    local quest = activeQuests[currentQuestID]
    if insideDestCell and quest.metaData.destCellClearedStage ~= nil then
        if quest.playerQuest.stage < quest.destCellClearedStage then
            enemiesInCurrentDestCell = getEnemies()
            if #enemiesInCurrentDestCell == 0 then
                --- yay we did it
                quest.playerQuest:addJournalEntry(quest.metaData.destCellClearedStage, pself)
            end
        end
    end
end

---@param data UrnEventData
local function onUrnPlacedStart(data)
    settings.debugPrint("started placing urn "..data.quest.id)
    --- this is just here to notify the player that once they leave,
    --- the quest will be a success.
    local quest = activeQuests[data.quest.id]
    if quest == nil then
        error("placed urn " .. data.quest.id .. ", but the quest is inactive??")
        return
    end
    latestUrnData[data.quest.id] = data
    local clearedOut = false
    if quest.metaData.destCellClearedStage ~= nil then
        clearedOut = quest.playerQuest.stage == quest.metaData.destCellClearedStage
        if not clearedOut then
            settings.debugPrint("skipped journal update; enemies present")
        end
    else
        clearedOut = quest.playerQuest.stage < quest.metaData.placeStage
    end
    if clearedOut then
        quest.playerQuest:addJournalEntry(quest.metaData.placeStage, pself)
    end
end

local function onUrnPlacedDoneTHISISNOTGONNAWORK(data)
    settings.debugPrint("finished placing urn "..data.quest.id)
    --- this means the player left, and the urn is in the tomb without them.
    local quest = activeQuests[data.quest.id]
    if quest == nil then
        error("placed urn done " .. data.quest.id .. ", but the quest is inactive??")
        return
    end
    local clearedOut = false
    if quest.metaData.destCellClearedStage ~= nil then
        clearedOut = quest.playerQuest.stage == quest.metaData.destCellClearedStage
        if not clearedOut then
            settings.debugPrint("skipped journal update; enemies present")
        end
    else
        clearedOut = quest.playerQuest.stage < quest.metaData.placeCompleteStage
    end
    if clearedOut then
        quest.playerQuest:addJournalEntry(quest.metaData.placeCompleteStage, pself)
    end
end

return {
    eventHandlers = {
        [MOD_NAME .. "onUrnPlacedStart"] = onUrnPlacedStart,
        [MOD_NAME .. "onUrnPlacedDone"] = onUrnPlacedDone,
    },
    engineHandlers = {
        onActive = onActive,
        onUpdate = onUpdate,
        onQuestUpdate = onQuestUpdate,
    }
}
