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
local MOD_NAME                     = require("scripts.CryptKeeper.ns")
local content                      = require('openmw.content')
local const                     = require("scripts.CryptKeeper.const")

content.globals.records[const.URNS_LOST_GVAR] = 0
content.globals.records[const.URNS_DELIVERED_GVAR] = 0
