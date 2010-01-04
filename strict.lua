-- Based on struct.lua from lua's source tarball
-- checks uses of undeclared global variables
-- All global variables must be 'declared' through a regular assignment
-- (even assigning nil will do) in a main chunk before being used
-- anywhere or assigned to inside a function.

local getinfo      = debug.getinfo
local error        = error
local rawset       = rawset
local rawget       = rawget
local getmetatable = getmetatable
local setmetatable = setmetatable
local require      = require
local g            = _G

module("strict")

local function what ()
    local d = getinfo(3, "S")
    return d and d.what or "C"
end

-- This function is *only* called when an undefined variable is read.
local function my__index(t, n)
    if what() ~= "C" then
        error("variable '"..n.."' is not declared", 2)
    end
    return rawget(t, n)
end

local function catch_invalid_uses(t)
    local mt = getmetatable(t)
    if mt == nil then
        mt = {}
        setmetatable(t, mt)
    end

    if not mt.__index then
        mt.__index = my__index
    end
end

-- Overwrite require with a version which adds the __index meta call
function g.require(what)
    local res = require(what)
    catch_invalid_uses(res)
    return res
end

catch_invalid_uses(g)

-- Don't allow anything which is not in global context to add new variables to
-- the global context.
getmetatable(g).__newindex = function (t, n, v)
    local w = what()
    if w ~= "main" and w ~= "C" then
        error("assign to undeclared variable '"..n.."'", 2)
    end
    rawset(t, n, v)
end
