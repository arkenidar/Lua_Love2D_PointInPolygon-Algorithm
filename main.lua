--- debuggers

-- https://github.com/pkulchenko/MobDebug in e.g. ZeroBrane Studio IDE
if arg[#arg] == "-debug" then require("mobdebug").start() end -- see docs

-- https://love2d.org/forums/viewtopic.php?t=88570
-- https://stackoverflow.com/questions/65066037/how-to-debug-lua-love2d-with-vscode
-- tomblind.local-lua-debugger-vscode in Microsoft VisualStudio Code: see also ".vscode/launch.json"
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end -- see docs

-- global objects:

function love.load()
  love.window.setTitle("Love2D - Concave Polygon PIP Algorithm ( concavity removal re-formulation technique ) ")
  love.window.setMode(500, 500, { resizable = true }) -- set window size
  -- from: http://notebook.kulchenko.com/zerobrane/love2d-debugging
  if arg[#arg] == "-debug" then require("mobdebug").start() end
end

-- current polygon ( initially empty , add vertices with mouse )
-- poligono corrente (inizialmente vuoto, aggiungi vertici con il mouse)
local polygon = {} -- initially empty

-- example polygons
-- note: "concave polygon" support check
local polygon1 = { { x = 50, y = 50 }, { x = 50, y = 100 }, { x = 70, y = 70 }, { x = 100, y = 100 }, { x = 100, y = 50 }, } -- concave

local polygon2 = { { 50, 50 }, { 50, 100 }, { 70, 70 }, { 100, 100 }, { 100, 50 }, }                                         -- concave

-----------------------------------
-- https://love2d.org/forums/viewtopic.php?p=239370#p239370
local function inside_polygon(polygon, point)
  local last = polygon[#polygon]
  for i = 1, #polygon do
    local current = polygon[i]

    local function halfplane(px, p1, p2)
      return ((p2[1] - p1[1]) * (px[2] - p1[2]) - (p2[2] - p1[2]) * (px[1] - p1[1])) >= 0
    end

    if halfplane(point, last, current) then
      return false
    end

    last = current
  end
  return true
end
-----------------------------------

function draw_polygon(polygon)
  for x = 0, 500 do
    for y = 0, 500 do
      local is_inside
      is_inside = in_concave_polygon(x, y, polygon) -- concave polygons also. such as 5-pointed stars.
      ---is_inside = inside_polygon(polygon2, {x,y}) -- convex polygons only. not concave. such as triangles.
      if is_inside then
        love.graphics.points({ { x, y } })
      end
    end
  end
end

function set_polygon(new)
  polygon = new
end

function love.draw()
  draw_polygon(polygon)
end

function sign(x)
  if x == 0 then
    return 0
  elseif x > 0 then
    return 1
  else
    return -1
  end
end

function side(px, p1, p2)
  return sign((p2.x - p1.x) * (px.y - p1.y) - (p2.y - p1.y) * (px.x - p1.x))
end

function ring_index(index, size)
  if index <= size then
    if index < 1 then
      return index + size
    else
      return index
    end
  else
    return index - size
  end
end

-- x,y: a given point, polygon: a polygon (list of points)
function in_convex_polygon(x, y, polygon)
  -- minimum of 3 vertices
  -- minimo 3 vertici oppure considerato punto esterno.
  if #polygon < 3 then return false end

  local point = { x = x, y = y }
  for i = 1, #polygon do
    local i1, i2
    i1 = ring_index(i, #polygon)
    i2 = ring_index(i + 1, #polygon)
    if side(point, polygon[i1], polygon[i2]) > 0 then
      return false
    end
  end

  return true
end

function in_concave_polygon(x, y, polygon)
  -- minimum of 3 vertices
  -- minimo 3 vertici oppure considerato punto esterno.
  if #polygon < 3 then return false end

  while true do
    -- find the first concavity vertex if there is one
    -- trova la prima concavità se c'è, ovvero
    -- il primo vertice che rende questo poligono un poligono concavo.
    local p = polygon
    local first_concavity_vertex = nil

    for i = 1, #polygon do
      local i1, i2, i3
      i1 = ring_index(i + 1, #polygon)
      i2 = ring_index(i - 1, #polygon)
      i3 = ring_index(i, #polygon)
      local is_concavity = side(p[i1], p[i2], p[i3]) == 1
      if is_concavity then
        first_concavity_vertex = i
        break
      end
    end

    -- if no concavity is found then the polygon is convex
    -- senza concavità il poligono è convesso.
    -- (la gestione dei poligoni convessi è semplice
    -- e si combina con questa casistica dei poligoni anche concavi
    -- se almeno una concavità è presente).
    if first_concavity_vertex == nil then
      return in_convex_polygon(x, y, polygon)
    end

    -- if polygon is concave:
    -- se il poligono è concavo:

    -- form a "concavity triangle"
    -- 1 - forma un triangolo di concavità
    -- con il vertice concavo ed i 2 vertici adiacenti
    local vertex_index = first_concavity_vertex

    local i1, i2, i3
    i1 = ring_index(vertex_index + 1, #polygon)
    i2 = ring_index(vertex_index, #polygon)
    i3 = ring_index(vertex_index - 1, #polygon)
    local concavity = { polygon[i1], polygon[i2], polygon[i3] }

    -- if point in "concavity triangle" return false (outside)
    -- 2 - se il punto è nel triangolo di concavità (passo 1)
    -- il punto è fuori
    if in_convex_polygon(x, y, concavity) then
      return false
    end

    -- form a new (!) polygon with the concavity removed
    -- 3 - forma un nuovo poligono con questa concavità rimossa
    -- (o meglio con rimosso il punto della prima concavità)

    local new_polygon = {}
    for i = 1, #polygon do
      if i ~= vertex_index then
        table.insert(new_polygon, polygon[i])
      end
    end

    -- go to the cycle beginning using the polygon
    -- with the concavity removed as a polygon to test
    -- 4 - ripeti ma usando il nuovo poligono con
    -- quel punto di concavità rimosso (passo 3) come poligono da testare
    polygon = new_polygon
  end
end

-- from: https://love2d.org/wiki/Debug
function love.keypressed(key, u)
  --Debug
  if key == "rctrl" then
    --set to whatever key you want to use
    --currently bound to RightControl key
    debug.debug()
  end
end

function love.mousepressed(x, y, button, istouch, presses)
  -- add a vertex to the polygon
  -- aggiungi un vertice al poligono
  table.insert(polygon, { x = x, y = y })
end
