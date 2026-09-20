-- Bare SELECT cycles the Gen II display pipeline when no item owns SELECT.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.harness")
local eq = T.eq
local Game2 = require("src.core.Game2")
local Input = require("src.core.Input")

local function subject(registered)
  local calls, persisted = {}, 0
  local game = setmetatable({
    stack = { top = function() return nil end },
    world = { registeredItemId = function() return registered end },
    options = {}, save = {},
    pipelineHotkey = function(_, key, options, persist)
      calls[#calls + 1] = key
      persist()
      return true
    end,
    persistOptions = function() persisted = persisted + 1 end,
  }, { __index = Game2 })
  return game, calls, function() return persisted end
end

local joy = {
  isGamepad = function() return true end,
  isGamepadDown = function() return false end,
}

Input:init()
local game, calls, persisted = subject(nil)
game:gamepadpressed(joy, "back")
eq(calls[1], "3", "bare Select uses Dramatic Shape pipeline hotkey")
eq(persisted(), 1, "pipeline selection persists")
eq(game.save.options, game.options, "pipeline options attach to save")

Input:init()
game, calls = subject("BICYCLE")
game:gamepadpressed(joy, "back")
eq(#calls, 0, "registered item retains Select")

T.finish()
