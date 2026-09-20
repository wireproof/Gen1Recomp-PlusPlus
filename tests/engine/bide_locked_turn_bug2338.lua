package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local BattleState = require("src.battle.BattleState")
local Font = require("src.render.Font")
local Pokemon = require("src.pokemon.Pokemon")
local SaveData = require("src.core.SaveData")
local TypeChart = require("src.battle.TypeChart")

local data = T.fixtures.fresh()
Font.load(data)
TypeChart.load(data)

local save = SaveData.newGame()
save.party = { Pokemon.new(data, "FIXMON_A", 20) }
local stack = { states = {} }
function stack:push(state) self.states[#self.states + 1] = state end
function stack:pop() return table.remove(self.states) end
function stack:top() return self.states[#self.states] end

local game = {
  data = data,
  save = save,
  stack = stack,
  input = {
    wasPressed = function() return false end,
    isDown = function() return false end,
  },
}

local battle = BattleState.newWild(game, "FIXMON_B", 10)
battle.queue = {}
battle.player.bideTurns = 3
battle.player.bideDamage = 0
battle:continueBide(battle.player, battle.enemy)

T.eq(battle.player.bideTurns, 2, "a locked Bide turn still counts down")
for _, row in ipairs(battle.queue) do
  T.check(not (row.text and row.text:find("storing energy", 1, true)),
    "a locked Bide turn does not repeat the storing-energy message (#2338)")
end

T.finish("bide locked turn message (#2338)")
