package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = T.fixtures.fresh()
Data.tilesets.FIX_OUT.tilesPerRow = 16
Data.field.flyWarps = Data.field.flyWarps or {}
Data.field.playerSprites = { walk = "SPRITE_FIX_PLAYER" }
Data.field.waterTilesets = {}
Data.field.forcedMovement = { tiles = {} }
Data.field.seafoam = {
  FIX_TOWN = {
    holeDestination = "FIX_ROUTE",
    holes = { { x = 5, y = 6, boulderEvent = "EVENT_FIX_BOULDER_DOWN" } },
  },
}

local Game = require("src.core.Game")
local Input = require("src.core.Input")
local Renderer = require("src.render.Renderer")
local SaveData = require("src.core.SaveData")
local StateStack = require("src.core.StateStack")
local OW = require("src.world.OverworldController")

Game.data = Data
Game.input = Input
Input:init()
Game.renderer = Renderer
Renderer:init()
Game.stack = StateStack
StateStack:init()
Game.save = SaveData.newGame()

Game.stack:push(OW, "FIX_TOWN", 4, 6, "right")
local ow = Game.stack:top()
local boulder = { cellX = 5, cellY = 6, def = { name = "FIX_BOULDER" } }
ow.npcs[#ow.npcs + 1] = boulder
ow.entities[#ow.entities + 1] = boulder

T.check(ow:boulderIntoHole(boulder), "the boulder falls through its hole")
T.eq(Game.stack:top(), ow,
  "the boulder drop does not open a message box (#2290)")
T.eq(Game.save.flags.EVENT_FIX_BOULDER_DOWN, true,
  "the boulder event is still recorded")

T.finish("boulder drop message (#2290)")
