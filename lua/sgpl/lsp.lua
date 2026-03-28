#!/usr/bin/env lua
-- SGPL Language Server Protocol implementation
-- Provides: diagnostics, completion, hover

-- Minimal JSON library
local json = {}

function json.encode(val)
  if val == nil then return "null" end
  local t = type(val)
  if t == "boolean" then return val and "true" or "false" end
  if t == "number" then return tostring(val) end
  if t == "string" then
    return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"')
      :gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
  end
  if t == "table" then
    if #val > 0 or next(val) == nil then
      local parts = {}
      for _, v in ipairs(val) do parts[#parts + 1] = json.encode(v) end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      local parts = {}
      for k, v in pairs(val) do
        parts[#parts + 1] = json.encode(k) .. ":" .. json.encode(v)
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  end
  return "null"
end

function json.decode(str)
  local pos = 1
  local function skip_ws()
    pos = str:find("[^ \t\n\r]", pos) or #str + 1
  end
  local parse_value
  local function parse_string()
    pos = pos + 1
    local start = pos
    local result = {}
    while pos <= #str do
      local c = str:sub(pos, pos)
      if c == '\\' then
        table.insert(result, str:sub(start, pos - 1))
        pos = pos + 1
        c = str:sub(pos, pos)
        if c == 'n' then table.insert(result, '\n')
        elseif c == 't' then table.insert(result, '\t')
        elseif c == 'r' then table.insert(result, '\r')
        elseif c == '"' then table.insert(result, '"')
        elseif c == '\\' then table.insert(result, '\\')
        elseif c == '/' then table.insert(result, '/')
        elseif c == 'u' then pos = pos + 4; table.insert(result, '?')
        end
        pos = pos + 1; start = pos
      elseif c == '"' then
        table.insert(result, str:sub(start, pos - 1))
        pos = pos + 1
        return table.concat(result)
      else pos = pos + 1
      end
    end
    return table.concat(result)
  end
  local function parse_number()
    local start = pos
    if str:sub(pos, pos) == '-' then pos = pos + 1 end
    while pos <= #str and str:sub(pos, pos):match("[%d%.eE%+%-]") do pos = pos + 1 end
    return tonumber(str:sub(start, pos - 1))
  end
  local function parse_object()
    pos = pos + 1; skip_ws()
    local obj = {}
    if str:sub(pos, pos) == '}' then pos = pos + 1; return obj end
    while true do
      skip_ws(); local key = parse_string()
      skip_ws(); pos = pos + 1; skip_ws()
      obj[key] = parse_value()
      skip_ws()
      if str:sub(pos, pos) == ',' then pos = pos + 1
      elseif str:sub(pos, pos) == '}' then pos = pos + 1; return obj end
    end
  end
  local function parse_array()
    pos = pos + 1; skip_ws()
    local arr = {}
    if str:sub(pos, pos) == ']' then pos = pos + 1; return arr end
    while true do
      skip_ws(); arr[#arr + 1] = parse_value(); skip_ws()
      if str:sub(pos, pos) == ',' then pos = pos + 1
      elseif str:sub(pos, pos) == ']' then pos = pos + 1; return arr end
    end
  end
  parse_value = function()
    skip_ws()
    local c = str:sub(pos, pos)
    if c == '"' then return parse_string()
    elseif c == '{' then return parse_object()
    elseif c == '[' then return parse_array()
    elseif c == 't' then pos = pos + 4; return true
    elseif c == 'f' then pos = pos + 5; return false
    elseif c == 'n' then pos = pos + 4; return nil
    else return parse_number() end
  end
  return parse_value()
end

-- LSP I/O
local function read_message()
  local headers = {}
  while true do
    local line = io.read("*l")
    if not line then return nil end
    if line == "" or line == "\r" then break end
    line = line:gsub("\r$", "")
    local key, val = line:match("^([^:]+):%s*(.+)$")
    if key then headers[key:lower()] = val end
  end
  local len = tonumber(headers["content-length"])
  if not len then return nil end
  return json.decode(io.read(len))
end

local function send(msg)
  local body = json.encode(msg)
  io.write("Content-Length: " .. #body .. "\r\n\r\n" .. body)
  io.flush()
end

local function respond(id, result)
  send({ jsonrpc = "2.0", id = id, result = result })
end

local function notify(method, params)
  send({ jsonrpc = "2.0", method = method, params = params })
end

-- Shape info for completion/hover
local shapes = {
  ellipse = {
    desc = "Draws an ellipse",
    params = {
      { "major_axis", "Length of the major axis", "10" },
      { "minor_axis", "Length of the minor axis", "10" },
      { "thickness", "Line thickness", "2" },
      { "x_center", "X center coordinate", "0" },
      { "y_center", "Y center coordinate", "0" },
      { "r", "Red (0-255)", "255" },
      { "g", "Green (0-255)", "255" },
      { "b", "Blue (0-255)", "255" },
      { "fill_r", "Fill red (0-255)", "none" },
      { "fill_g", "Fill green (0-255)", "none" },
      { "fill_b", "Fill blue (0-255)", "none" },
    },
  },
  circle = {
    desc = "Draws a circle (alias for ellipse)",
    params = {
      { "radius", "Circle radius", "10" },
      { "thickness", "Line thickness", "2" },
      { "x_center", "X center", "0" }, { "y_center", "Y center", "0" },
      { "r", "Red", "255" }, { "g", "Green", "255" }, { "b", "Blue", "255" },
      { "fill_r", "Fill red (0-255)", "none" },
      { "fill_g", "Fill green (0-255)", "none" },
      { "fill_b", "Fill blue (0-255)", "none" },
    },
  },
  rectangle = {
    desc = "Draws a rectangle",
    params = {
      { "height", "Height", "10" }, { "length", "Length", "10" },
      { "thickness", "Thickness", "2" },
      { "x_center", "X center", "0" }, { "y_center", "Y center", "0" },
      { "r", "Red", "255" }, { "g", "Green", "255" }, { "b", "Blue", "255" },
      { "fill_r", "Fill red (0-255)", "none" },
      { "fill_g", "Fill green (0-255)", "none" },
      { "fill_b", "Fill blue (0-255)", "none" },
    },
  },
  square = {
    desc = "Draws a square (alias for rectangle)",
    params = {
      { "side_length", "Side length", "10" }, { "thickness", "Thickness", "2" },
      { "x_center", "X center", "0" }, { "y_center", "Y center", "0" },
      { "r", "Red", "255" }, { "g", "Green", "255" }, { "b", "Blue", "255" },
      { "fill_r", "Fill red (0-255)", "none" },
      { "fill_g", "Fill green (0-255)", "none" },
      { "fill_b", "Fill blue (0-255)", "none" },
    },
  },
  triangle = {
    desc = "Draws a triangle from three vertices",
    params = {
      { "x1", "Vertex 1 X", "0" }, { "y1", "Vertex 1 Y", "0" },
      { "x2", "Vertex 2 X", "10" }, { "y2", "Vertex 2 Y", "0" },
      { "x3", "Vertex 3 X", "5" }, { "y3", "Vertex 3 Y", "8.66" },
      { "thickness", "Thickness", "2" },
      { "x_center", "X offset", "0" }, { "y_center", "Y offset", "0" },
      { "r", "Red", "255" }, { "g", "Green", "255" }, { "b", "Blue", "255" },
      { "fill_r", "Fill red (0-255)", "none" },
      { "fill_g", "Fill green (0-255)", "none" },
      { "fill_b", "Fill blue (0-255)", "none" },
    },
  },
  arrow = {
    desc = "Draws an arrow (optionally curved)",
    params = {
      { "x_start", "Start X", "0" }, { "y_start", "Start Y", "0" },
      { "x_end", "End X", "10" }, { "y_end", "End Y", "10" },
      { "thickness", "Thickness", "2" }, { "head_size", "Head size", "8" },
      { "head_type", "Head: none/arrow/diamond/circle/square", "arrow" },
      { "tail_type", "Tail: none/arrow/diamond/circle/square", "none" },
      { "curvature", "Bezier curvature (0=straight)", "0" },
      { "head", "Target shape for smart connection", "none" },
      { "tail", "Source shape for smart connection", "none" },
      { "avoid_above", "Route arrow below with curvature", "0" },
      { "avoid_below", "Route arrow above with curvature", "0" },
      { "r", "Red", "255" }, { "g", "Green", "255" }, { "b", "Blue", "255" },
    },
  },
  text = {
    desc = "Draws text",
    params = {
      { "literal", "Text content", '""' },
      { "font", "Font family", '"Times New Roman"' },
      { "font_size", "Font size", "12" },
      { "x_center", "X position", "0" }, { "y_center", "Y position", "0" },
      { "r", "Red", "255" }, { "g", "Green", "255" }, { "b", "Blue", "255" },
    },
  },
  canvas = {
    desc = "Creates an output canvas",
    params = {
      { "width", "Width in pixels", "100" }, { "height", "Height in pixels", "100" },
      { "r", "Background red", "255" }, { "g", "Background green", "255" },
      { "b", "Background blue", "255" },
      { "name", "Output filename", "auto" },
    },
  },
}

local keywords = { "if", "for", "while", "draw", "print", "import", "struct", "return" }

local documents = {}

local function get_diagnostics(text)
  local diags = {}
  local brace, paren, in_str = 0, 0, false
  local line_num = 0
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local in_comment = false
    for i = 1, #line do
      local c = line:sub(i, i)
      if in_comment then break
      elseif c == '#' and not in_str then in_comment = true
      elseif c == '"' then in_str = not in_str
      elseif not in_str then
        if c == '{' then brace = brace + 1
        elseif c == '}' then brace = brace - 1
        elseif c == '(' then paren = paren + 1
        elseif c == ')' then paren = paren - 1 end
      end
    end
    if brace < 0 then
      diags[#diags + 1] = { range = { start = { line = line_num, character = 0 }, ["end"] = { line = line_num, character = #line } }, severity = 1, message = "Unexpected '}'" }
      brace = 0
    end
    if paren < 0 then
      diags[#diags + 1] = { range = { start = { line = line_num, character = 0 }, ["end"] = { line = line_num, character = #line } }, severity = 1, message = "Unexpected ')'" }
      paren = 0
    end
    line_num = line_num + 1
  end
  if brace > 0 then
    diags[#diags + 1] = { range = { start = { line = line_num - 1, character = 0 }, ["end"] = { line = line_num - 1, character = 0 } }, severity = 1, message = "Unclosed '{'" }
  end
  if paren > 0 then
    diags[#diags + 1] = { range = { start = { line = line_num - 1, character = 0 }, ["end"] = { line = line_num - 1, character = 0 } }, severity = 1, message = "Unclosed '('" }
  end
  return diags
end

local function get_word_at(text, line, char)
  local cur = 0
  for l in (text .. "\n"):gmatch("([^\n]*)\n") do
    if cur == line then
      local s, e = char + 1, char + 1
      while s > 1 and l:sub(s - 1, s - 1):match("[%w_]") do s = s - 1 end
      while e <= #l and l:sub(e, e):match("[%w_]") do e = e + 1 end
      return l:sub(s, e - 1)
    end
    cur = cur + 1
  end
  return ""
end

-- Main loop
local shutdown = false
while true do
  local msg = read_message()
  if not msg then break end
  local method = msg.method

  if method == "initialize" then
    respond(msg.id, {
      capabilities = {
        textDocumentSync = { openClose = true, change = 1 },
        completionProvider = { triggerCharacters = { "(", ",", " " } },
        hoverProvider = true,
      },
      serverInfo = { name = "sgpl-lsp", version = "0.2.0" },
    })
  elseif method == "initialized" then
    -- ok
  elseif method == "shutdown" then
    shutdown = true; respond(msg.id, nil)
  elseif method == "exit" then
    os.exit(shutdown and 0 or 1)
  elseif method == "textDocument/didOpen" then
    local doc = msg.params.textDocument
    documents[doc.uri] = doc.text
    notify("textDocument/publishDiagnostics", { uri = doc.uri, diagnostics = get_diagnostics(doc.text) })
  elseif method == "textDocument/didChange" then
    local uri = msg.params.textDocument.uri
    if msg.params.contentChanges[1] then
      documents[uri] = msg.params.contentChanges[1].text
      notify("textDocument/publishDiagnostics", { uri = uri, diagnostics = get_diagnostics(documents[uri]) })
    end
  elseif method == "textDocument/didClose" then
    documents[msg.params.textDocument.uri] = nil
  elseif method == "textDocument/completion" then
    local items = {}
    for name, info in pairs(shapes) do
      items[#items + 1] = { label = name, kind = 7, detail = info.desc, insertText = name .. "($0)", insertTextFormat = 2 }
    end
    for _, kw in ipairs(keywords) do
      items[#items + 1] = { label = kw, kind = 14 }
    end
    -- Add shape params if we're inside a shape call
    local uri = msg.params.textDocument.uri
    local text = documents[uri] or ""
    for name, info in pairs(shapes) do
      if text:find(name .. "%s*%(") then
        for _, p in ipairs(info.params) do
          items[#items + 1] = { label = p[1], kind = 5, detail = p[2] .. " (default: " .. p[3] .. ")", insertText = p[1] .. " = " }
        end
      end
    end
    respond(msg.id, items)
  elseif method == "textDocument/hover" then
    local uri = msg.params.textDocument.uri
    local text = documents[uri]
    if text then
      local word = get_word_at(text, msg.params.position.line, msg.params.position.character)
      local info = shapes[word]
      if info then
        local lines = { "**" .. word .. "** - " .. info.desc, "", "Parameters:" }
        for _, p in ipairs(info.params) do
          lines[#lines + 1] = "- `" .. p[1] .. "`: " .. p[2] .. " (default: " .. p[3] .. ")"
        end
        respond(msg.id, { contents = { kind = "markdown", value = table.concat(lines, "\n") } })
      else
        respond(msg.id, nil)
      end
    else
      respond(msg.id, nil)
    end
  elseif msg.id then
    send({ jsonrpc = "2.0", id = msg.id, error = { code = -32601, message = "Method not found" } })
  end
end
