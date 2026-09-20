-- Bare SELECT cycles the Gen II display pipeline when no item owns SELECT.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.harness")
local eq = T.eq
local Game2 = require("src.core.Game2")
local Input = require("src.core.Input")
local Player = require("src.world.gen2.Player")

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

local function subjectWithWorldOnTop(registered)
  local game, calls, persisted = subject(registered)
  game.stack.top = function() return game.world end
  return game, calls, persisted
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
game, calls, persisted = subjectWithWorldOnTop(nil)
game:gamepadpressed(joy, "back")
eq(calls[1], "3", "bare Select also works when World is the live top state")
eq(persisted(), 1, "live-world pipeline selection persists")

Input:init()
game, calls = subject("BICYCLE")
game:gamepadpressed(joy, "back")
eq(#calls, 0, "registered item retains Select")

local player = Player.new(3, 4, "left")
player.sprite = { marker = "gen2-player" }
player.spriteYOffset = -2
player.stepFlip = true
local sprite, x, y, facing, phase, flip, hopping = player:pose()
eq(sprite, player.sprite, "Gen II player exposes its sprite to world pipelines")
eq(x, 48, "Gen II player pose reports pixel x")
eq(y, 62, "Gen II player pose applies the sprite y offset")
eq(facing, "left", "Gen II player pose reports facing")
eq(phase, 0, "idle Gen II player pose reports the standing phase")
eq(flip, true, "Gen II player pose reports its walking flip")
eq(hopping, false, "Gen II player pose has no Gen I hop flag")

T.finish()
