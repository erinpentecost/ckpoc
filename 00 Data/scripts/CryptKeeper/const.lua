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


--[[
Prioritized TOPIC_ASH_INTERMENT dialogue responses:

URN_DELIVERY_ACTIVE_GVAR=1 AND HAS_URN_GVAR=1:
    - "Deliver your charge to their final resting place." No side-effects.
URN_DELIVERY_ACTIVE_GVAR=1 AND HAS_URN_GVAR=0: "Was the internment successful?" Choice of responding:
    - "I lost the remains." This should have an attached result mwscript that contains the string "CK_LOST_URN".
       This will notify the lua that the active quest should be killed.
       This could be done in a per-quest dialogue topic, but I'd like to avoid
       per-quest topics since there are probably going to be a ton.
    - "Goodbye." No side-effects.
Urn quest stage is 50: "<custom success completion response for the quest>". Advance quest stage to 100 in the mwscript! There's one of these per delivery quest.
Urn quest stage is 0: "<custom response for start of the quest>". Advance quest stage to 10 in the mwscript! There's one of these per delivery quest.
]]

return {
    --- this is searched for in mwscript to cancel the current quest
    MWS_LOST_URN_TOKEN = "CK_LOST_URN",
    --- topic to get interment quests
    TOPIC_ASH_INTERMENT = "ash interment",
    --- count of total urns lost
    URNS_LOST_GVAR = "x32_CS_UrnsLost",
    --- count of total urns delivered
    URNS_DELIVERED_GVAR = "x32_CS_UrnsDelivered",
    --- 1 if the player is carrying an urn right now
    HAS_URN_GVAR = "x32_CS_UrnCarried",
    --- 1 if the player has an urn delivery quest active
    URN_DELIVERY_ACTIVE_GVAR = "x32_CS_UrnDeliveryActive",
}
