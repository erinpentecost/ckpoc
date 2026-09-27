--[[
ErnCryptKeeper for OpenMW.
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

return {
    --- count of total urns lost
    URNS_LOST_GVAR = "x32_CS_UrnsLost",
    --- count of total urns delivered
    URNS_DELIVERED_GVAR = "x32_CS_UrnsDelivered",
    --- 1 if the player is carrying an urn right now
    HAS_URN_GVAR = "x32_CS_UrnCarried",
    --- 1 if the player has an urn delivery quest active
    URN_DELIVERY_ACTIVE_GVAR = "x32_CS_UrnDeliveryActive",
}
