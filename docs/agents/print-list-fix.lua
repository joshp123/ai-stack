-- Pandoc Lua filter: attach immediate paragraphs to single-item lists.
-- This fixes Markdown that uses one-item lists followed by unindented paragraphs.
local function is_para_like(block)
  return block.t == "Para" or block.t == "Plain"
end

local function get_items(list)
  if list.c then
    local first_type = pandoc.utils.type(list.c[1])
    if first_type == "Blocks" then
      return list.c
    end
  end
  if list.t == "OrderedList" then
    if list.c and list.c[2] then
      return list.c[2]
    end
    if list.items then
      return list.items
    end
    if list[2] then
      return list[2]
    end
    return nil
  end
  if list.t == "BulletList" then
    if list.c then
      return list.c
    end
    if list.items then
      return list.items
    end
    return nil
  end
  return nil
end

local function set_items(list, items)
  if list.c then
    local first_type = pandoc.utils.type(list.c[1])
    if first_type == "Blocks" then
      list.c = items
      return
    end
  end
  if list.t == "OrderedList" then
    if list.c and list.c[2] then
      list.c[2] = items
      return
    end
    if list.items then
      list.items = items
      return
    end
    if list[2] then
      list[2] = items
      return
    end
    return
  else
    if list.c then
      list.c = items
      return
    end
    if list.items then
      list.items = items
      return
    end
    return
  end
end

local function item_to_blocks(item)
  local t = pandoc.utils.type(item)
  if t == "Block" then
    return { item }
  end
  local out = {}
  for i = 1, #item do
    out[i] = item[i]
  end
  return out
end

function Pandoc(doc)
  local out = {}
  local blocks = doc.blocks
  local i = 1

  while i <= #blocks do
    local b = blocks[i]
    if (b.t == "OrderedList" or b.t == "BulletList") then
      local items = get_items(b)
      if #items == 1 then
        local item = item_to_blocks(items[1])
        local j = i + 1
        while j <= #blocks and is_para_like(blocks[j]) do
          item[#item + 1] = blocks[j]
          j = j + 1
        end
        if item[1] and item[1].t == "Plain" then
          item[1] = pandoc.Para(item[1].c)
        end
        items[1] = item
        set_items(b, items)
        table.insert(out, b)
        i = j
      else
        table.insert(out, b)
        i = i + 1
      end
    else
      table.insert(out, b)
      i = i + 1
    end
  end

  return pandoc.Pandoc(out, doc.meta)
end
