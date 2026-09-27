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

---Performs a binary search on a list sorted in ascending order by valueFn,
---returning the index at which an item with the given score should be inserted.
---@generic T
---@param list T[] A list already sorted in ascending order by valueFn
---@param score number The score to find the insertion index for
---@param valueFn fun(record: T): number Returns the score to sort by
---@return number index
local function binarySearchInsertIndex(list, score, valueFn)
    local low = 1
    local high = #list

    while low <= high do
        local mid = math.floor((low + high) / 2)
        local midValue = valueFn(list[mid])

        if midValue <= score then
            low = mid + 1
        else
            high = mid - 1
        end
    end

    return low
end

---Inserts item into list to keep it sorted in ascending order by valueFn(item).
---If ensureUnique is true, does not insert the item if its valueFn output
---is already present in the list.
---@generic T
---@param list T[] A list already sorted in ascending order by valueFn
---@param item T The item to insert
---@param valueFn fun(record: T): number Returns the score to sort by
---@param ensureUnique boolean|nil If true, returns nil instead of inserting a duplicate value
---@return number|nil index The index the item was inserted at, or nil if a duplicate was found
local function binaryInsert(list, item, valueFn, ensureUnique)
    local value = valueFn(item)
    local index = binarySearchInsertIndex(list, value, valueFn)

    if ensureUnique and index > 1 and valueFn(list[index - 1]) == value then
        return nil
    end

    table.insert(list, index, item)
    return index
end

---Shuffles the values of a collection and returns them in a new array.
---@generic T
---@param collection table<any, T> The input collection (can be a list or dictionary).
---@return T[] # A new array containing the shuffled elements.
local function shuffle(collection)
    local randList = {}
    for _, item in pairs(collection) do
        -- get random index to insert into. 1 to size+1.
        -- # is a special op that gets size
        local insertAt = math.random(1, 1 + #randList)
        table.insert(randList, insertAt, item)
    end
    return randList
end

return {
    shuffle = shuffle,
    binarySearchInsertIndex = binarySearchInsertIndex,
    binaryInsert = binaryInsert,
}
