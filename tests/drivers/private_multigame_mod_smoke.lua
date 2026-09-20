-- Boots a real imported ROM and verifies that both bundled private mods load
-- together without loader errors. Used by the private seven-game release
-- audit; it intentionally exercises the normal Game/Game2/Game3 startup path.
local GameVersion = require("src.core.GameVersion")

return function(game)
  for _ = 1, 30 do coroutine.yield() end

  local expected = assert(os.getenv("POKEPORT_VERSION"), "POKEPORT_VERSION missing")
  assert(GameVersion.get() == expected,
    ("booted %s, expected %s"):format(tostring(GameVersion.get()), expected))
  assert(game and game.mods, "game did not install the mod loader")

  local status = game.mods:status()
  assert(#(status.errors or {}) == 0,
    "mod loader reported errors: " .. table.concat(status.errors or {}, "; "))

  local loaded = {}
  for _, manifest in ipairs(status.loaded or {}) do loaded[manifest.id] = manifest end
  assert(loaded.kanto_johto_gear, "Kanto/Johto Gear did not load")
  assert(loaded.kanto_johto_gear.version == "1.0.0-beta.6",
    "unexpected Kanto/Johto Gear version")
  assert(loaded.DRAMATIC_SHAPE, "Dramatic Shape did not load")

  local dramatic = loaded.DRAMATIC_SHAPE
  assert(dramatic.version == "1.8.0-multigen.4",
    "unexpected Dramatic Shape version")

  print(("[seven-game-smoke] PASS %s gear=%s dramatic=%s"):format(
    expected, loaded.kanto_johto_gear.version, dramatic.version))
  love.filesystem.write("private-multigame-smoke-" .. expected .. ".txt", "PASS\n")
  love.event.quit()
end
