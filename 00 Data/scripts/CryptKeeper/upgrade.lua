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
local core         = require("openmw.core")
local types     = require("openmw.types")
local world        = require("openmw.world")
local aux_util = require('openmw_aux.util')
local shuffle = require("scripts.CryptKeeper.shuffle")
local settings     = require("scripts.CryptKeeper.settings.settings")
local MOD_NAME  = require("scripts.CryptKeeper.ns")
local localization       = core.l10n(MOD_NAME)
local const        = require("scripts.CryptKeeper.const")
local itemutil        = require("scripts.CryptKeeper.itemutil")


---@alias WeaponImprovement
---| 1 -- health
---| 2 -- enchantCapacity
---| 3 -- weight
---| 4 -- speed
---| 5 -- maxDamage

---@enum WeaponImprovements
local WEAPON_IMPROVEMENTS = {
    health = 1,
    enchantCapacity = 2,
    weight = 3,
    speed = 4,
    maxDamage = 5,
}

---@alias ArmorImprovement
---| 1 -- health
---| 2 -- enchantCapacity
---| 3 -- weight
---| 4 -- baseArmor

---@enum ArmorImprovements
local ARMOR_IMPROVEMENTS = {
    health = 1,
    enchantCapacity = 2,
    weight = 3,
    baseArmor = 4,
}

--- This tracks records for "improved" items, which are dynamically generated records
--- that clone items in the allowlist and tweak them to be stronger.
--- This list is generated lazilly.
--- There are 9 quality levels for every item.
--- All items of the same quality should re-use the same record.
--- I need a map of original_item_record_id -> upgrade table.
--- the upgrade table is a map of quality level (a number) to a generated item record id.
--- quality 0 should point back at the original_item_record_id.
--- I also need the reverse lookup: a generated item record id back to the original_item_record_id.
--- that will allow me to upgrade items sequentially.
---
--- potential weapon stats to modify:
--- * max damage
--- * min damage (maybe skip this one, since it is not independent of max damage)
--- * condition (health)
--- * enchantcapacity?
--- * weight
--- * value (this should always go up)
--- * speed
---
--- potential armor stats to modify:
--- * baseArmor
--- * condition (health)
--- * enchantcapacity?
--- * weight
--- * value (this should always go up)
---
--- This is saved onLoad because it must follow the savegame.
--- Dynamically generated records are not valid across differenct characters,
--- and may not be valid across different saves of the same character.
---@class Persisted
---@field upgradeMap {[string]: string | {[number]: string}}
---@field weaponImprovementMap {[string]: WeaponImprovement[]}
---@field armorImprovementMap {[string]: ArmorImprovement[]}

---@type Persisted
local persist      = {
    upgradeMap = {},
    weaponImprovementMap = {},
    armorImprovementMap = {}
}


---@alias UpgradeTable {[number]: string}

---@param itemRecordID string
---@return UpgradeTable?
local function getUpgradeTable(itemRecordID)
    --- get the value. if it's a string, do another lookup.
    local lookup = persist.upgradeMap[itemRecordID]
    if not lookup then
        return
    end
    if type(lookup) == "string" then
        -- this branch happens if itemRecordID was for an upgraded version.
        return getUpgradeTable(lookup)
    end
    return lookup
end

---@param itemRecordID string
---@return string?
local function getBaseItemRecordID(itemRecordID)
    local lookup = persist.upgradeMap[itemRecordID]
    if not lookup then
        return nil
    end
    if type(lookup) == "table" then
        return itemRecordID
    elseif type(lookup) == "string" then
        return lookup
    else
        error("bad type in upgradeMap for "..tostring(itemRecordID))
    end
end

---@param itemRecordID string
---@param newTable UpgradeTable
local function setUpgradeTable(itemRecordID, newTable)
    settings.debugPrint("setUpgradeTable(" ..tostring(itemRecordID)..", ".. aux_util.deepToString(newTable, 5) .. ")")
    local baseID = getBaseItemRecordID(itemRecordID) or itemRecordID
    persist.upgradeMap[baseID] = newTable
    -- also register the reverse lookup for every generated level, so that
    -- upgrading an already-upgraded item finds its way back to this same
    -- table instead of being treated as a brand new base item.
    for level, recordID in pairs(newTable) do
        if level ~= 0 then
            persist.upgradeMap[recordID] = baseID
        end
    end
end

---Return a random list of improvements, with an even-ish distribution.
---@param baseItemRecordID string -- record ID for the un-upgraded item.
---@return WeaponImprovement[]
local function weaponImprovementsByLevel(baseItemRecordID)
    --- get cached list
    if persist.weaponImprovementMap[baseItemRecordID] then
        local existing = persist.weaponImprovementMap[baseItemRecordID]
        if #existing ~= const.MAX_QUALITY then
            error("missing improvement entries for " .. tostring(baseItemRecordID))
        end
        return existing
    end
    --- build new list
    local rand = shuffle(WEAPON_IMPROVEMENTS)
    while #rand < const.MAX_QUALITY do
        for _, v in ipairs(shuffle(WEAPON_IMPROVEMENTS)) do
            if #rand < const.MAX_QUALITY then
                rand[#rand + 1] = v
            end
        end
    end
    persist.weaponImprovementMap[baseItemRecordID] = rand
    return rand
end

---Return a random list of improvements, with an even-ish distribution.
---@param baseItemRecordID string -- record ID for the un-upgraded item.
---@return ArmorImprovement[]
local function armorImprovementsByLevel(baseItemRecordID)
    --- get cached list
    if persist.armorImprovementMap[baseItemRecordID] then
        local existing = persist.armorImprovementMap[baseItemRecordID]
        if #existing ~= const.MAX_QUALITY then
            error("missing improvement entries for " .. tostring(baseItemRecordID))
        end
        return existing
    end
    --- build new list
    local rand = shuffle(ARMOR_IMPROVEMENTS)
    while #rand < const.MAX_QUALITY do
        for _, v in ipairs(shuffle(ARMOR_IMPROVEMENTS)) do
            if #rand < const.MAX_QUALITY then
                rand[#rand + 1] = v
            end
        end
    end
    persist.armorImprovementMap[baseItemRecordID] = rand
    return rand
end

---@type {[ArmorImprovement]: fun(table): table}
local armorImprovementOperators = {
    [ARMOR_IMPROVEMENTS.health] = function(record)
        return {
        health = math.ceil(math.max(record.health + 10, record.health*1.05))
        }
    end,
    [ARMOR_IMPROVEMENTS.enchantCapacity] = function(record)
        return {
        enchantCapacity = math.ceil(record.enchantCapacity + 3)
        }
    end,
    [ARMOR_IMPROVEMENTS.weight] = function(record)
        return {
        weight = math.ceil(math.max(1, math.min(record.weight - 1, record.weight*.95)))
        }
    end,
    [ARMOR_IMPROVEMENTS.baseArmor] = function(record)
        return {
        baseArmor = math.ceil(math.max(record.baseArmor + 1, record.baseArmor*1.05))
        }
    end,
}

---@type {[WeaponImprovement]: fun(table): table}
local weaponImprovementOperators = {
    [WEAPON_IMPROVEMENTS.health] = function(record)
        return {
        health = math.ceil(math.max(record.health + 10, record.health*1.05))
        }
    end,
    [WEAPON_IMPROVEMENTS.enchantCapacity] = function(record)
        return {
        enchantCapacity = math.ceil(record.enchantCapacity + 3)
        }
    end,
    [WEAPON_IMPROVEMENTS.weight] = function(record)
        return {
        weight = math.ceil(math.max(0.5, math.min(record.weight - 1, record.weight*.95)))
        }
    end,
    [WEAPON_IMPROVEMENTS.speed] = function(record)
        --round up to nearest 0.05
        local speed = record.speed + .05
        speed = math.ceil(speed / 0.05) * 0.05
        return {
        speed = speed
        }
    end,
    [WEAPON_IMPROVEMENTS.maxDamage] = function(record)
        return {
            chopMaxDamage = record.chopMaxDamage + 1,
            slashMaxDamage = record.slashMaxDamage + 1,
            thrustMaxDamage = record.thrustMaxDamage + 1,
        }
    end,
}

---Returns true if the given record is an Armor record.
---@param record table a weapon or armor record
---@return boolean
local function isArmorRecord(record)
    return types.Armor.records[record.id] ~= nil
end

---Returns true if the given record is a Weapon record.
---@param record table a weapon or armor record
---@return boolean
local function isWeaponRecord(record)
    return types.Weapon.records[record.id] ~= nil
end

---Returns the type module (types.Armor or types.Weapon) that a record belongs to.
---Needed because createRecordDraft() is a static function on the type module
---(e.g. types.Armor.createRecordDraft(record)), not a method on the record itself.
---@param record table a weapon or armor record
---@return table?
local function getRecordTypeModule(record)
    if isArmorRecord(record) then
        return types.Armor
    elseif isWeaponRecord(record) then
        return types.Weapon
    else
        --- this can happen for clothing.
        return nil
    end
end

---this is pretty gross ngl
---@param baseItemRecord table
---@return (fun(table): table)[]
local function improvementModifiers(baseItemRecord)
    local isArmor = isArmorRecord(baseItemRecord)
    local out = {}
    local fn
    local map
    if isArmor then
        fn = armorImprovementsByLevel
        map = armorImprovementOperators
    else
        fn = weaponImprovementsByLevel
        map = weaponImprovementOperators
    end
    for k, v in ipairs(fn(baseItemRecord.id)) do
        out[k] = map[v]
    end
	return out
end

---Returns the new name of an item with an adjective.
---@param baseItemRecord table
---@param quality number
local function getNewName(baseItemRecord, quality)
    if quality < 1 then
        return baseItemRecord.name
    end
    if quality > const.MAX_QUALITY then
        quality = const.MAX_QUALITY
    end

    return localization("quality" .. tostring(quality), { name=baseItemRecord.name })
end

---Returns the current quality level of an item, whether it's the original
---(unupgraded) item or one of its generated upgrades.
---@param itemRecord table a weapon or armor record
---@return number level -- 0 to const.MAX_QUALITY
local function getCurrentLevel(itemRecord)
    local upgradeTable = getUpgradeTable(itemRecord.id)
    if not upgradeTable then
        return 0
    end
    for k, v in pairs(upgradeTable) do
        if v == itemRecord.id then
            return k
        end
    end
    return 0
end

---comment
---@param itemRecord table a weapon or armor record
---@param level number? either a number from 0 to 9, or nil. if nil, will return the next upgrade for the item.
---@return string?
local function getUpgradedRecordID(itemRecord, level)
    --- Don't generate upgrades for items that aren't in the allowlist (or are
    --- explicitly blocked). This checks the *base* item, since itemRecord may
    --- already be a generated upgrade of something on the allowlist.
    local baseItemRecordID = getBaseItemRecordID(itemRecord.id) or itemRecord.id
    if not itemutil.allowed(baseItemRecordID) then
        return itemRecord.id
    end

    local upgradeTable = getUpgradeTable(itemRecord.id)
    if not upgradeTable then
        -- build new upgrade table
        upgradeTable = {
            [0]=itemRecord.id
        }
        local lastRecord = itemRecord
        local recordTypeModule = getRecordTypeModule(itemRecord)
        if not recordTypeModule then
            return
        end
        for lvl, imp in pairs(improvementModifiers(itemRecord)) do
            local recFields = imp(lastRecord)
            recFields.name = getNewName(itemRecord, lvl)
            recFields.value = itemRecord.value + lvl * 10
            recFields.template = lastRecord
            settings.debugPrint("creating new record: " .. aux_util.deepToString(recFields, 5))
            local draft = recordTypeModule.createRecordDraft(recFields)
            local newRecord = world.createRecord(draft)
            if not newRecord then
                error("failed to upgrade " .. tostring(itemRecord.id) ..
                    " to level " .. tostring(lvl))
            end
            lastRecord = newRecord
            upgradeTable[lvl] = lastRecord.id
        end
        setUpgradeTable(itemRecord.id, upgradeTable)
    end
    -- get absolute level
    if level then
        if level < 0 or level > const.MAX_QUALITY then
            error("invalid level: "..tostring(level))
        end
        return upgradeTable[level]
    end
    --- find current level, then return the next one
    local currentLevel = getCurrentLevel(itemRecord)
    return upgradeTable[math.min(const.MAX_QUALITY, currentLevel + 1)]
end

local function onLoad(data)
    if data then
        persist = data
    end
end
local function onSave()
    return persist
end

return {
    interfaceName = MOD_NAME.."_Upgrade",
    interface = {
        version = 1,
        getUpgradeTable = getUpgradeTable,
        getUpgradedRecordID = getUpgradedRecordID,
        getCurrentLevel = getCurrentLevel,
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
}
