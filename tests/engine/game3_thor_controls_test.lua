-- AYN Thor controller fallbacks used by FireRed.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.harness")
local Game3 = require("src.core.Game3")

local hotkey
local game = setmetatable({
  input = { wasPressed = function(_, key) return key == "select" end },
  session = {},
  _hotkey = function(_, key) hotkey = key return true end,
}, { __index = Game3 })
game:_handleRegisteredItem()
T.eq(hotkey, "3", "bare FireRed SELECT reaches the Dramatic pipeline")

local toggles = 0
game = setmetatable({
  input = {
    isDown = function() return false end,
    padAction = function(_, button)
      return button == "leftshoulder" and "speedToggle" or nil
    end,
  },
  _toggleSpeed = function() toggles = toggles + 1 end,
}, { __index = Game3 })
game:_padPressedBody(nil, "leftshoulder")
T.eq(toggles, 1, "Thor shoulder-labelled trigger toggles FireRed speed")

local f = assert(io.open("src/core/Game3.lua", "rb"))
local source = f:read("*a")
f:close()
T.check(source:find('ModRuntime.call("input.pointer"', 1, true) ~= nil,
  "FireRed forwards unclaimed lower-screen touches to companion mods")

T.finish("game3 Thor controls")
