local wezterm = require 'wezterm'
local act = wezterm.action

local function bounds(panes)
  local left, top = math.huge, math.huge
  local right, bottom = -math.huge, -math.huge
  for _, pane in ipairs(panes) do
    left = math.min(left, pane.left)
    top = math.min(top, pane.top)
    right = math.max(right, pane.left + pane.width)
    bottom = math.max(bottom, pane.top + pane.height)
  end
  return { width = right - left, height = bottom - top }
end

local function build_tree(panes)
  if #panes == 1 then
    local pane = panes[1]
    return { type = 'pane', pane = pane, width = pane.width, height = pane.height }
  end

  local function find_cut(axis)
    local start_key = axis == 'x' and 'left' or 'top'
    local size_key = axis == 'x' and 'width' or 'height'
    local edges = {}
    for _, pane in ipairs(panes) do
      edges[pane[start_key] + pane[size_key]] = true
    end
    local sorted = {}
    for edge in pairs(edges) do sorted[#sorted + 1] = edge end
    table.sort(sorted)

    for _, edge in ipairs(sorted) do
      local first, second = {}, {}
      for _, pane in ipairs(panes) do
        local start = pane[start_key]
        local finish = start + pane[size_key]
        if finish <= edge then
          first[#first + 1] = pane
        elseif start >= edge then
          second[#second + 1] = pane
        end
      end
      if #first > 0 and #second > 0 and #first + #second == #panes then
        return first, second
      end
    end
  end

  for _, axis in ipairs({ 'x', 'y' }) do
    local first, second = find_cut(axis)
    if first then
      local a, b = build_tree(first), build_tree(second)
      local size = bounds(panes)
      if axis == 'x' then
        return { type = 'vsplit', first = a, second = b, width = size.width, height = size.height }
      end
      return { type = 'hsplit', first = a, second = b, width = size.width, height = size.height }
    end
  end
end

local function count(node, split_type)
  if node.type == split_type then
    return count(node.first, split_type) + count(node.second, split_type)
  end
  return 1
end

local function collect(node, result)
  result = result or {}
  if node.type == 'pane' then
    result[#result + 1] = node.pane
  else
    collect(node.first, result)
    collect(node.second, result)
  end
  return result
end

local function boundary_pair(first, second, vertical)
  local first_panes, second_panes = collect(first), collect(second)
  local first_edge, second_edge = -math.huge, math.huge
  for _, pane in ipairs(first_panes) do
    first_edge = math.max(first_edge, vertical and pane.left + pane.width or pane.top + pane.height)
  end
  for _, pane in ipairs(second_panes) do
    second_edge = math.min(second_edge, vertical and pane.left or pane.top)
  end

  local best_first, best_second, best_overlap = nil, nil, -1
  for _, a in ipairs(first_panes) do
    local a_edge = vertical and a.left + a.width or a.top + a.height
    if a_edge == first_edge then
      for _, b in ipairs(second_panes) do
        local b_edge = vertical and b.left or b.top
        if b_edge == second_edge then
          local a_start = vertical and a.top or a.left
          local b_start = vertical and b.top or b.left
          local a_end = a_start + (vertical and a.height or a.width)
          local b_end = b_start + (vertical and b.height or b.width)
          local overlap = math.max(0, math.min(a_end, b_end) - math.max(a_start, b_start))
          if overlap > best_overlap then best_first, best_second, best_overlap = a, b, overlap end
        end
      end
    end
  end
  return best_first, best_second
end

local function snapshot(tab)
  local result = {}
  for _, pane in ipairs(tab:panes_with_info()) do result[pane.index] = pane end
  return result
end

local function same_layout(first, second)
  for index, pane in pairs(first) do
    local other = second[index]
    if not other or pane.left ~= other.left or pane.top ~= other.top
      or pane.width ~= other.width or pane.height ~= other.height then
      return false
    end
  end
  for index in pairs(second) do
    if not first[index] then return false end
  end
  return true
end

local function undo_probe(window, tab, before, after, negative)
  if same_layout(before, after) then return true end
  pcall(function()
    window:perform_action(act.AdjustPaneSize({ negative, 1 }), tab:active_pane())
  end)
  return same_layout(before, snapshot(tab))
end

local function probe_boundary(window, tab, candidate, verify, property, direction, reverse)
  local before = snapshot(tab)
  pcall(function()
    window:perform_action(act.ActivatePaneByIndex(candidate.index), tab:active_pane())
    window:perform_action(act.AdjustPaneSize({ direction, 1 }), tab:active_pane())
  end)
  local after = snapshot(tab)
  local candidate_delta = before[candidate.index] and after[candidate.index]
    and after[candidate.index][property] - before[candidate.index][property]
  local verify_delta = before[verify.index] and after[verify.index]
    and after[verify.index][property] - before[verify.index][property]
  if not undo_probe(window, tab, before, after, reverse) then
    wezterm.log_warn('Equalize panes: could not restore boundary probe; stopping')
    return nil
  end
  if candidate_delta and verify_delta and candidate_delta ~= 0 and verify_delta == -candidate_delta then
    return candidate_delta
  end
end

local function adjust_boundary(window, tab, node, delta)
  local vertical = node.type == 'vsplit'
  local property = vertical and 'width' or 'height'
  local toward = vertical and 'Right' or 'Down'
  local away = vertical and 'Left' or 'Up'
  local first, second = boundary_pair(node.first, node.second, vertical)
  if not first then return false end

  local change = probe_boundary(window, tab, first, second, property, toward, away)
  local candidate = first
  if change == nil then
    change = probe_boundary(window, tab, second, first, property, away, toward)
    if change == nil then return false end
    change = -change
    candidate = second
    toward, away = away, toward
  end
  local direction = delta * change > 0 and toward or away
  window:perform_action(act.ActivatePaneByIndex(candidate.index), tab:active_pane())
  window:perform_action(act.AdjustPaneSize({ direction, math.abs(delta) }), tab:active_pane())
  return true
end

local function equalize(window)
  local tab = window:active_tab()
  local original = tab:active_pane()
  local panes = tab:panes_with_info()
  if #panes < 2 then return end
  for _, pane in ipairs(panes) do
    if pane.is_zoomed then
      wezterm.log_warn('Equalize panes: unzoom the active pane first')
      return
    end
  end

  local ok, err = xpcall(function()
    for _ = 1, #panes - 1 do
      local current = tab:panes_with_info()
      local tree = build_tree(current)
      if not tree then break end
      local queue, changed = { tree }, false
      local head = 1
      while head <= #queue and not changed do
        local node = queue[head]
        head = head + 1
        if node.type == 'vsplit' or node.type == 'hsplit' then
          local split_type = node.type
          local first_weight = count(node.first, split_type)
          local second_weight = count(node.second, split_type)
          local property = split_type == 'vsplit' and 'width' or 'height'
          local total = node[property]
          local current_size = node.first[property]
          local target = math.floor(total * first_weight / (first_weight + second_weight))
          local delta = target - current_size
          if delta ~= 0 then changed = adjust_boundary(window, tab, node, delta) end
          if not changed then
            queue[#queue + 1] = node.first
            queue[#queue + 1] = node.second
          end
        end
      end
      if not changed then break end
    end
  end, debug.traceback)

  if original then pcall(function() original:activate() end) end
  if not ok then wezterm.log_error('Equalize panes failed: ' .. tostring(err)) end
end

return equalize
