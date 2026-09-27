---@meta openmw.util

-- This file provides Lua Language Server annotations for OpenMW's `openmw.util` module.

---@class util
local util = {}

--==================================================
-- Vector2
--==================================================

---@class Vector2
---@field x number
---@field y number
---@field xy01 any
local Vector2 = {}

---@param v Vector2
---@return Vector2
function Vector2:__add(v) end

---@param v Vector2
---@return Vector2
function Vector2:__sub(v) end

---@param k number
---@return Vector2
function Vector2:__mul(k) end

---@param k number
---@return Vector2
function Vector2:__div(k) end

---@param v Vector2
---@return number
function Vector2:dot(v) end

---@param v Vector2
---@return Vector2
function Vector2:ediv(v) end

---@param v Vector2
---@return Vector2
function Vector2:emul(v) end

---@return number
function Vector2:length() end

---@return number
function Vector2:length2() end

---@return Vector2, number
function Vector2:normalize() end

---@param angle number
---@return Vector2
function Vector2:rotate(angle) end

--==================================================
-- Vector3
--==================================================

---@class Vector3
---@field x number
---@field y number
---@field z number
---@field xyz01 any
local Vector3 = {}

---@param v Vector3
---@return Vector3
function Vector3:__add(v) end

---@param v Vector3
---@return Vector3
function Vector3:__sub(v) end

---@param k number
---@return Vector3
function Vector3:__mul(k) end

---@param k number
---@return Vector3
function Vector3:__div(k) end

---@return string
function Vector3:__tostring() end

---@param v Vector3
---@return Vector3
function Vector3:cross(v) end

---@param v Vector3
---@return number
function Vector3:dot(v) end

---@param v Vector3
---@return Vector3
function Vector3:ediv(v) end

---@param v Vector3
---@return Vector3
function Vector3:emul(v) end

---@return number
function Vector3:length() end

---@return number
function Vector3:length2() end

---@return Vector3, number
function Vector3:normalize() end

--==================================================
-- Vector4
--==================================================

---@class Vector4
---@field x number
---@field y number
---@field z number
---@field w number
---@field xyzw01 any
local Vector4 = {}

---@param v Vector4
---@return Vector4
function Vector4:__add(v) end

---@param v Vector4
---@return Vector4
function Vector4:__sub(v) end

---@param k number
---@return Vector4
function Vector4:__mul(k) end

---@param k number
---@return Vector4
function Vector4:__div(k) end

---@return string
function Vector4:__tostring() end

---@param v Vector4
---@return number
function Vector4:dot(v) end

---@param v Vector4
---@return Vector4
function Vector4:ediv(v) end

---@param v Vector4
---@return Vector4
function Vector4:emul(v) end

---@return number
function Vector4:length() end

---@return number
function Vector4:length2() end

---@return Vector4, number
function Vector4:normalize() end

--==================================================
-- Transform
--==================================================

---@class Transform
local Transform = {}

---@param t Transform
---@return Transform
function Transform:__mul(t) end

---@param v Vector3
---@return Vector3
function Transform:apply(v) end

---@return number, number
function Transform:getAnglesXZ() end

---@return number, number, number
function Transform:getAnglesZYX() end

---@return number
function Transform:getPitch() end

---@return number
function Transform:getYaw() end

---@return Transform
function Transform:inverse() end

--==================================================
-- Box
--==================================================

---@class Box
---@field center Vector3
---@field halfSize Vector3
---@field transform Transform
---@field vertices Vector3[]
local Box = {}

--==================================================
-- Color
--==================================================

---@class Color
---@field r number
---@field g number
---@field b number
---@field a number
local Color = {}

---@return string
function Color:asHex() end

---@return Vector3
function Color:asRgb() end

---@return Vector4
function Color:asRgba() end

--==================================================
-- util.color
--==================================================

---@class COLOR
local COLOR = {}

---@param str string
---@return Color
function COLOR.commaString(str) end

---@param hex string
---@return Color
function COLOR.hex(hex) end

---@param r number
---@param g number
---@param b number
---@return Color
function COLOR.rgb(r, g, b) end

---@param r number
---@param g number
---@param b number
---@param a number
---@return Color
function COLOR.rgba(r, g, b, a) end

--==================================================
-- util.transform
--==================================================

---@class TRANSFORM
local TRANSFORM = {}

---@type Transform
TRANSFORM.identity = nil

---@overload fun(offset: Vector3): Transform
---@param x number
---@param y number
---@param z number
---@return Transform
function TRANSFORM.move(x, y, z) end

---@param angle number
---@param axis Vector3
---@return Transform
function TRANSFORM.rotate(angle, axis) end

---@param angle number
---@return Transform
function TRANSFORM.rotateX(angle) end

---@param angle number
---@return Transform
function TRANSFORM.rotateY(angle) end

---@param angle number
---@return Transform
function TRANSFORM.rotateZ(angle) end

---@overload fun(scale: Vector3): Transform
---@param x number
---@param y number
---@param z number
---@return Transform
function TRANSFORM.scale(x, y, z) end

--==================================================
-- util functions
--==================================================

---@param x number
---@param y number
---@return Vector2
function util.vector2(x, y) end

---@param x number
---@param y number
---@param z number
---@return Vector3
function util.vector3(x, y, z) end

---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function util.vector4(x, y, z, w) end

---@param t Transform
---@return Box
function util.box(t) end

---@param value number
---@param from number
---@param to number
---@return number
function util.clamp(value, from, to) end

---@param value number
---@param min number
---@param max number
---@param newMin number
---@param newMax number
---@return number
function util.remap(value, min, max, newMin, newMax) end

---@param value number
---@return number
function util.round(value) end

---@param angle number
---@return number
function util.normalizeAngle(angle) end

---@param code string
---@param env table
---@return function
function util.loadCode(code, env) end

---@param t table
---@return table
function util.makeReadOnly(t) end

---@param t table
---@return table
function util.makeStrictReadOnly(t) end

---@vararg number
---@return number
function util.bitAnd(...) end

---@param a number
---@return number
function util.bitNot(a) end

---@vararg number
---@return number
function util.bitOr(...) end

---@vararg number
---@return number
function util.bitXor(...) end

---@type COLOR
util.color = COLOR

---@type TRANSFORM
util.transform = TRANSFORM

return util
