-- Fit landscape label art.
local Art = {}

local function canvas(w, h, draw)
  local g = love.graphics
  local result = g.newCanvas(w, h)
  local previous = g.getCanvas()
  g.push("all")
  g.setCanvas(result)
  g.origin()
  g.setShader()
  g.setScissor()
  g.setBlendMode("alpha")
  g.clear(0, 0, 0, 0)
  draw(g)
  g.setCanvas(previous)
  g.pop()
  result:setFilter("linear", "linear")
  return { image = result, width = w, height = h }
end

local function externalLabel(imp)
  if imp._gbaExternalLabel ~= nil then return imp._gbaExternalLabel or nil end
  imp._gbaExternalLabel = false
  local path = os.getenv("POKEPORT_CART_LABEL")
  if not path or path == "" then return nil end
  local ok, result = pcall(function()
    local f = assert(io.open(path, "rb"))
    local bytes = f:read("*a")
    f:close()
    local image = love.graphics.newImage(love.filesystem.newFileData(bytes, path))
    local w, h = image:getDimensions()
    return { image = image, width = w, height = h }
  end)
  if ok then imp._gbaExternalLabel = result
  else require("src.core.Logger").error("GBA label: %s", tostring(result)) end
  return imp._gbaExternalLabel or nil
end

function Art.label(imp, skin, original)
  imp._gbaLabels = imp._gbaLabels or {}
  if imp._gbaLabels[skin.cacheKey] then return imp._gbaLabels[skin.cacheKey] end
  local source = externalLabel(imp) or original
  if not source then
    if imp._gbaDefaultLabel == nil then
      imp._gbaDefaultLabel = false
      local ok, image = pcall(love.graphics.newImage,
        "assets/labels/gba-green-blue.png")
      if ok and image then
        local sized, w, h = pcall(image.getDimensions, image)
        if sized and type(w) == "number" and type(h) == "number"
            and w > 0 and h > 0 then
          imp._gbaDefaultLabel = { image = image, width = w, height = h }
        end
      end
    end
    source = imp._gbaDefaultLabel or nil
  end
  local label = canvas(512, 260, function(g)
    local c = skin.color
    for y = 0, 259 do
      local shade = 0.24 + 0.32 * (1 - y / 260)
      g.setColor(c[1] / 255 * shade, c[2] / 255 * shade, c[3] / 255 * shade, 1)
      g.rectangle("fill", 0, y, 512, 1)
    end
    if source then
      local scale = math.min(512 / source.width, 260 / source.height)
      g.setColor(1, 1, 1, 1)
      g.draw(source.image, (512 - source.width * scale) / 2,
        (260 - source.height * scale) / 2, 0, scale, scale)
    else
      -- A missing or unreadable optional label must never take down the
      -- launcher. Draw a neutral inset so the cartridge remains usable.
      g.setColor(1, 1, 1, 0.16)
      g.rectangle("fill", 20, 18, 472, 224)
      g.setColor(0, 0, 0, 0.18)
      g.rectangle("line", 20, 18, 472, 224)
    end
  end)
  imp._gbaLabels[skin.cacheKey] = label
  return label
end

return Art
