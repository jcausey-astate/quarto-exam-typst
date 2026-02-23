-- Auto-generate exam header from YAML metadata
-- Also provides shorthand syntax for common Typst exam functions

-- Default mapping of shorthand syntax to Typst code (when exam-question-layout is "wide" or unset)
local shorthand_map = {
  ["{{vf}}"] = "#vf()",
  ["{{sblank}}"] = "#sblank()",
  ["{{blank}}"] = "#blank()",
  ["{{ssblank}}"] = "#ssblank()",
  ["{{lblank}}"] = "#lblank()",
  ["{{begin-narrow}}"] = "#narrow([",
  ["{{end-narrow}}"] = "])",
  ["{{begin-wide}}"] = "#wide([",
  ["{{end-wide}}"] = "])",
}

-- Helper function to generate dynamic width code that respects layout context
-- Returns two values: (needs_context, width_expr)
-- If needs_context is true, the caller must wrap the block in a context expression
-- and use the width_expr as the width value
local function get_width_info(explicit_width)
  if explicit_width == "100%" then
    -- Explicit wide - no context needed
    return false, "100%"
  elseif explicit_width == "narrow" then
    -- Explicit narrow width - needs context to get the state value
    return true, "exam-question-width-state.get()"
  elseif explicit_width then
    -- Other explicit width (shouldn't happen, but handle it)
    return false, explicit_width
  else
    -- Dynamic width - needs context to determine based on current mode
    return true, "{ let mode = exam-question-layout-state.get(); let fw = force-wide-state.get(); if mode == \"narrow\" and not fw { exam-question-width-state.get() } else { 100% } }"
  end
end

-- Convert a Quarto column width attribute (e.g. "50%") to a Typst column size
local function column_width_to_typst(width_attr)
  if not width_attr then return "1fr" end
  local pct = width_attr:match("^(%d+%.?%d*)%%$")
  if pct then
    return pct .. "%"
  end
  return "1fr"
end

-- Escape special characters for pattern matching
local function escape_pattern(text)
  return text:gsub("[%-%.%+%*%?%[%]%(%)%^%$%%]", "%%%1")
end

-- Process Str elements (plain text) - this is where inline text gets processed
function Str(elem)
  -- First check for parameterized shortcodes (pts:N and ptseach:N)
  -- Pattern matches {{pts:NUMBER}} or {{ptseach:NUMBER}}
  local text = elem.text
  local result = {}
  local pos = 1

  while pos <= #text do
    -- Try to match {{pts:N}} or {{ptseach:N}}
    local start_pos, end_pos, cmd, param = text:find("{{(pts):(%d+)}}", pos)
    if not start_pos then
      start_pos, end_pos, cmd, param = text:find("{{(ptseach):(%d+)}}", pos)
    end

    if start_pos then
      -- Add text before the shortcode
      if start_pos > pos then
        table.insert(result, pandoc.Str(text:sub(pos, start_pos - 1)))
      end
      -- Add the Typst code with parameter
      local typst_code = string.format("#%s([%s])", cmd, param)
      table.insert(result, pandoc.RawInline("typst", typst_code))
      pos = end_pos + 1
    else
      -- No more parameterized shortcodes, check for simple shortcodes
      local found = false
      for shorthand, typst_code in pairs(shorthand_map) do
        local sh_start, sh_end = text:find(escape_pattern(shorthand), pos, true)
        if sh_start and sh_start == pos then
          -- Found a simple shortcode at current position
          table.insert(result, pandoc.RawInline("typst", typst_code))
          pos = sh_end + 1
          found = true
          break
        end
      end

      if not found then
        -- No shortcode at current position, move forward character by character
        -- until we find a shortcode or reach the end
        local next_shortcode = #text + 1

        -- Check for parameterized shortcodes
        local p_start = text:find("{{pts:%d+}}", pos)
        if p_start and p_start < next_shortcode then
          next_shortcode = p_start
        end
        p_start = text:find("{{ptseach:%d+}}", pos)
        if p_start and p_start < next_shortcode then
          next_shortcode = p_start
        end

        -- Check for simple shortcodes
        for shorthand, _ in pairs(shorthand_map) do
          local sh_start = text:find(escape_pattern(shorthand), pos, true)
          if sh_start and sh_start < next_shortcode then
            next_shortcode = sh_start
          end
        end

        -- Add text up to next shortcode (or end of string)
        table.insert(result, pandoc.Str(text:sub(pos, next_shortcode - 1)))
        pos = next_shortcode
      end
    end
  end

  -- If we found any shortcodes, return the result list
  if #result > 0 then
    return result
  end

  return elem
end

-- Handle inline spans with custom classes [text]{.classname}
function Span(elem)
  -- Check if span has classes
  if #elem.classes > 0 then
    -- Map class names to Typst text sizes
    -- based on https://tex.stackexchange.com/a/24600
    local size_map = {
      ["tiny"] = "0.5em",
      ["scriptsize"] = "0.7em",
      ["footnotesize"] = "0.8em",
      ["small"] =  "0.9em",
      ["normalsize"] = "1.0em",
      ["large"] = "1.2em",
      ["Large"] = "1.44em",
      ["LARGE"] = "1.728em",
      ["huge"] = "2.074em",
      ["Huge"] = "2.488em",
      ["HUGE"] = "2.728em", -- custom to our template
    }

    -- Map class names to relative Typst text sizes (em units scale relative to inherited size)
    local relative_size_map = {
      ["smaller"] = "0.85em",
      ["larger"] = "1.2em",
    }

    -- Map class names to Typst colors
    local color_map = {
      ["red"] = "red",
      ["blue"] = "blue",
      ["green"] = "green",
      ["orange"] = "orange",
      ["purple"] = "purple",
      ["gray"] = "gray",
      ["grey"] = "gray",
    }

    -- Map class names to highlight colors (pale backgrounds)
    local highlight_map = {
      ["highlight"] = "rgb(255, 255, 200)",      -- pale yellow
      ["highlight-yellow"] = "rgb(255, 255, 200)",
      ["highlight-green"] = "rgb(200, 255, 200)",
      ["highlight-blue"] = "rgb(200, 230, 255)",
      ["highlight-pink"] = "rgb(255, 200, 230)",
      ["highlight-orange"] = "rgb(255, 230, 200)",
    }

    -- Answer styling (subtle background + text color)
    local answer_style = {
      bg = "rgb(245, 255, 245)",  -- very subtle light green background
      fg = "rgb(50, 120, 50)"     -- darker green text
    }

    -- Collect all styling attributes
    local size = nil
    local color = nil
    local highlight = nil
    local is_answer = false
    local relative_size = nil

    for _, class in ipairs(elem.classes) do
      if size_map[class] then
        size = size_map[class]
      elseif color_map[class] then
        color = color_map[class]
      elseif highlight_map[class] then
        highlight = highlight_map[class]
      elseif class == "answer" then
        is_answer = true
      elseif relative_size_map[class] then
        relative_size = relative_size_map[class]
      end
    end

    -- Build the Typst code with combined styling
    if size or color or highlight or is_answer or relative_size then
      -- First, recursively process nested content (this will handle nested Spans)
      local processed_content = pandoc.walk_inline(elem, {
        Span = Span,
        Str = Str
      })

      -- Now we need to wrap the processed content
      -- We'll build a new Span with the styling and let Pandoc handle conversion
      local wrapped = elem
      wrapped.content = processed_content.content

      -- Build opening and closing Typst code
      local open_tags = {}
      local close_tags = {}

      -- Apply answer styling
      if is_answer then
        -- Answer gets subtle background box and text color
        table.insert(open_tags, string.format("#box(fill: %s, outset: 2pt, radius: 2pt)[", answer_style.bg))
        table.insert(open_tags, string.format("#text(fill: %s)[", answer_style.fg))
        table.insert(close_tags, 1, "]")
        table.insert(close_tags, 1, "]")
      end

      -- Apply text styling (size and/or color) first
      if size or color or relative_size then
        local params = {}
        if size then
          table.insert(params, string.format("size: %s", size))
        elseif relative_size then
          table.insert(params, string.format("size: %s", relative_size))
        end
        if color then
          table.insert(params, string.format("fill: %s", color))
        end
        table.insert(open_tags, string.format("#text(%s)[", table.concat(params, ", ")))
        table.insert(close_tags, 1, "]")  -- insert at beginning to close in reverse order
      end

      -- Apply highlight (box) on top if needed (but not if answer already applied)
      if highlight and not is_answer then
        table.insert(open_tags, string.format("#box(fill: %s, outset: 2pt, radius: 2pt)[", highlight))
        table.insert(close_tags, 1, "]")
      end

      -- Build result as a list of inlines
      local result = {}
      -- Add opening tags
      for _, tag in ipairs(open_tags) do
        table.insert(result, pandoc.RawInline("typst", tag))
      end
      -- Add processed content
      for _, item in ipairs(processed_content.content) do
        table.insert(result, item)
      end
      -- Add closing tags
      for _, tag in ipairs(close_tags) do
        table.insert(result, pandoc.RawInline("typst", tag))
      end

      return result
    end
  end
  return elem
end

-- Handle block divs with custom classes ::: {.classname}
function Div(elem)
  -- Guard: .column divs must be left as-is for the parent .columns handler to process,
  -- but we still apply any styling classes by injecting Typst code into the column content.
  local is_column = false
  for _, class in ipairs(elem.classes) do
    if class == "column" then is_column = true; break end
  end
  if is_column then
    -- Check for size/color/relative-size classes and inject wrapping into content
    local size_map = {
      ["tiny"] = "0.5em",
      ["scriptsize"] = "0.7em",
      ["footnotesize"] = "0.8em",
      ["small"] =  "0.9em",
      ["normalsize"] = "1.0em",
      ["large"] = "1.2em",
      ["Large"] = "1.44em",
      ["LARGE"] = "1.728em",
      ["huge"] = "2.074em",
      ["Huge"] = "2.488em",
      ["HUGE"] = "2.728em", -- custom to our template
    }
    local relative_size_map = { ["smaller"] = "0.85em", ["larger"] = "1.2em" }
    local color_map = {
      ["red"] = "red", ["blue"] = "blue", ["green"] = "green",
      ["orange"] = "orange", ["purple"] = "purple", ["gray"] = "gray", ["grey"] = "gray",
    }
    local size, color, relative_size = nil, nil, nil
    for _, class in ipairs(elem.classes) do
      if size_map[class] then size = size_map[class]
      elseif relative_size_map[class] then relative_size = relative_size_map[class]
      elseif color_map[class] then color = color_map[class]
      end
    end
    if size or color or relative_size then
      local params = {}
      if size then
        table.insert(params, string.format("size: %s", size))
      elseif relative_size then
        table.insert(params, string.format("size: %s", relative_size))
      end
      if color then table.insert(params, string.format("fill: %s", color)) end
      local new_content = {}
      table.insert(new_content, pandoc.RawBlock("typst", string.format("#block[\n#set text(%s)\n", table.concat(params, ", "))))
      for _, blk in ipairs(elem.content) do
        table.insert(new_content, blk)
      end
      table.insert(new_content, pandoc.RawBlock("typst", "]"))
      elem.content = new_content
    end
    return elem
  end

  -- Handle .columns (multi-column layout)
  for _, class in ipairs(elem.classes) do
    if class == "columns" then
      local col_widths = {}
      local col_contents = {}
      for _, child in ipairs(elem.content) do
        if child.t == "Div" then
          local child_is_column = false
          for _, cc in ipairs(child.classes) do
            if cc == "column" then child_is_column = true; break end
          end
          if child_is_column then
            local w = child.attributes["width"]
            table.insert(col_widths, column_width_to_typst(w))
            table.insert(col_contents, child.content)
          end
        end
      end

      if #col_widths == 0 then
        return elem
      end

      -- Collect any extra formatting classes (other than "columns") so they can be
      -- applied as an outer wrapper around the grid, as if the .columns div were
      -- nested inside a separate div carrying those classes.
      local col_size_map = {
        ["tiny"] = "0.5em",
        ["scriptsize"] = "0.7em",
        ["footnotesize"] = "0.8em",
        ["small"] =  "0.9em",
        ["normalsize"] = "1.0em",
        ["large"] = "1.2em",
        ["Large"] = "1.44em",
        ["LARGE"] = "1.728em",
        ["huge"] = "2.074em",
        ["Huge"] = "2.488em",
        ["HUGE"] = "2.728em", -- custom to our template
      }
      local col_relative_size_map = { ["smaller"] = "0.85em", ["larger"] = "1.2em" }
      local col_color_map = {
        ["red"] = "red", ["blue"] = "blue", ["green"] = "green",
        ["orange"] = "orange", ["purple"] = "purple", ["gray"] = "gray", ["grey"] = "gray",
      }
      local col_highlight_map = {
        ["highlight"] = "rgb(255, 255, 200)", ["highlight-yellow"] = "rgb(255, 255, 200)",
        ["highlight-green"] = "rgb(200, 255, 200)", ["highlight-blue"] = "rgb(200, 230, 255)",
        ["highlight-pink"] = "rgb(255, 200, 230)", ["highlight-orange"] = "rgb(255, 230, 200)",
      }
      local col_exambox_map = {
        ["exambox"]        = {fill = "rgb(240, 245, 255)", stroke = "rgb(100, 150, 255)"},
        ["exambox-blue"]   = {fill = "rgb(240, 245, 255)", stroke = "rgb(100, 150, 255)"},
        ["exambox-green"]  = {fill = "rgb(240, 255, 240)", stroke = "rgb(100, 200, 100)"},
        ["exambox-yellow"] = {fill = "rgb(255, 255, 230)", stroke = "rgb(200, 180, 0)"},
        ["exambox-red"]    = {fill = "rgb(255, 240, 240)", stroke = "rgb(220, 100, 100)"},
        ["exambox-orange"] = {fill = "rgb(255, 245, 230)", stroke = "rgb(220, 140, 60)"},
        ["exambox-gray"]   = {fill = "rgb(245, 245, 245)", stroke = "rgb(150, 150, 150)"},
      }
      local col_answer_style = { bg = "rgb(245, 255, 245)", fg = "rgb(50, 120, 50)" }

      local extra_size, extra_color, extra_highlight, extra_exambox = nil, nil, nil, nil
      local extra_is_answer, extra_relative_size, extra_explicit_width = false, nil, nil

      for _, cls in ipairs(elem.classes) do
        if cls ~= "columns" then
          if col_size_map[cls] then extra_size = col_size_map[cls]
          elseif col_color_map[cls] then extra_color = col_color_map[cls]
          elseif col_highlight_map[cls] then extra_highlight = col_highlight_map[cls]
          elseif col_exambox_map[cls] then extra_exambox = col_exambox_map[cls]
          elseif cls == "answer" then extra_is_answer = true
          elseif cls == "wide" then extra_explicit_width = "100%"
          elseif cls == "narrow" then extra_explicit_width = "narrow"
          elseif col_relative_size_map[cls] then extra_relative_size = col_relative_size_map[cls]
          end
        end
      end

      -- Build wrapper open/close Typst strings for any extra styling classes
      local open_wrapper, close_wrapper = nil, nil
      if extra_size or extra_color or extra_highlight or extra_exambox or extra_is_answer or extra_relative_size then
        local open_parts = {}
        local close_parts = {}
        local needs_context, width_expr = get_width_info(extra_explicit_width)

        if needs_context and (extra_exambox or extra_is_answer or extra_highlight) then
          table.insert(open_parts, string.format("#context { let _w = %s;\n", width_expr))
          table.insert(close_parts, "}")
        end
        if extra_exambox then
          local w = needs_context and "_w" or width_expr
          table.insert(open_parts, string.format(
            "block(fill: %s, stroke: (left: 3pt + %s, rest: 0.5pt + %s), radius: (top-right: 6pt, bottom-right: 6pt, rest: 0pt), inset: 10pt, width: %s)[\n",
            extra_exambox.fill, extra_exambox.stroke, extra_exambox.stroke, w))
          table.insert(close_parts, 1, "]")
        end
        if extra_is_answer and not extra_exambox then
          local w = needs_context and "_w" or width_expr
          table.insert(open_parts, string.format(
            "block(fill: %s, inset: 8pt, radius: 3pt, width: %s)[\n", col_answer_style.bg, w))
          table.insert(close_parts, 1, "]")
        end
        if extra_highlight and not extra_exambox and not extra_is_answer then
          local w = needs_context and "_w" or width_expr
          table.insert(open_parts, string.format(
            "box(fill: %s, inset: 8pt, radius: 4pt, width: %s)[\n", extra_highlight, w))
          table.insert(close_parts, 1, "]")
        end
        local params = {}
        if extra_size then
          table.insert(params, string.format("size: %s", extra_size))
        elseif extra_relative_size then
          table.insert(params, string.format("size: %s", extra_relative_size))
        end
        if extra_color then
          table.insert(params, string.format("fill: %s", extra_color))
        elseif extra_is_answer then
          table.insert(params, string.format("fill: %s", col_answer_style.fg))
        end
        if #params > 0 then
          table.insert(open_parts, "#block[\n")
          table.insert(open_parts, string.format("#set text(%s)\n", table.concat(params, ", ")))
          table.insert(close_parts, 1, "]")
        end
        if #open_parts > 0 then open_wrapper = table.concat(open_parts, "") end
        if #close_parts > 0 then close_wrapper = table.concat(close_parts, "\n") end
      end

      local cols_str = table.concat(col_widths, ", ")
      local result = {}
      if open_wrapper then
        table.insert(result, pandoc.RawBlock("typst", open_wrapper))
      end
      table.insert(result, pandoc.RawBlock("typst",
        string.format("#grid(columns: (%s), column-gutter: 1em,\n", cols_str)))
      for _, col_blocks in ipairs(col_contents) do
        table.insert(result, pandoc.RawBlock("typst", "["))
        for _, blk in ipairs(col_blocks) do
          table.insert(result, blk)
        end
        table.insert(result, pandoc.RawBlock("typst", "],"))
      end
      table.insert(result, pandoc.RawBlock("typst", ")"))
      if close_wrapper then
        table.insert(result, pandoc.RawBlock("typst", close_wrapper))
      end
      return result
    end
  end

  -- Check if div has classes
  if #elem.classes > 0 then
    -- Map class names to Typst text sizes
    local size_map = {
      ["tiny"] = "0.5em",
      ["scriptsize"] = "0.7em",
      ["footnotesize"] = "0.8em",
      ["small"] =  "0.9em",
      ["normalsize"] = "1.0em",
      ["large"] = "1.2em",
      ["Large"] = "1.44em",
      ["LARGE"] = "1.728em",
      ["huge"] = "2.074em",
      ["Huge"] = "2.488em",
      ["HUGE"] = "2.728em", -- custom to our template
    }

    -- Map class names to relative Typst text sizes (em units scale relative to inherited size)
    local relative_size_map = {
      ["smaller"] = "0.85em",
      ["larger"] = "1.2em",
    }

    -- Map class names to Typst colors
    local color_map = {
      ["red"] = "red",
      ["blue"] = "blue",
      ["green"] = "green",
      ["orange"] = "orange",
      ["purple"] = "purple",
      ["gray"] = "gray",
      ["grey"] = "gray",
    }

    -- Map class names to highlight colors (pale backgrounds)
    local highlight_map = {
      ["highlight"] = "rgb(255, 255, 200)",      -- pale yellow
      ["highlight-yellow"] = "rgb(255, 255, 200)",
      ["highlight-green"] = "rgb(200, 255, 200)",
      ["highlight-blue"] = "rgb(200, 230, 255)",
      ["highlight-pink"] = "rgb(255, 200, 230)",
      ["highlight-orange"] = "rgb(255, 230, 200)",
    }

    -- Map exambox classes with their styling
    local exambox_map = {
      ["exambox"] = {fill = "rgb(240, 245, 255)", stroke = "rgb(100, 150, 255)"},
      ["exambox-blue"] = {fill = "rgb(240, 245, 255)", stroke = "rgb(100, 150, 255)"},
      ["exambox-green"] = {fill = "rgb(240, 255, 240)", stroke = "rgb(100, 200, 100)"},
      ["exambox-yellow"] = {fill = "rgb(255, 255, 230)", stroke = "rgb(200, 180, 0)"},
      ["exambox-red"] = {fill = "rgb(255, 240, 240)", stroke = "rgb(220, 100, 100)"},
      ["exambox-orange"] = {fill = "rgb(255, 245, 230)", stroke = "rgb(220, 140, 60)"},
      ["exambox-gray"] = {fill = "rgb(245, 245, 245)", stroke = "rgb(150, 150, 150)"},
    }

    -- Answer styling (subtle background + text color)
    local answer_style = {
      bg = "rgb(245, 255, 245)",  -- very subtle light green background
      fg = "rgb(50, 120, 50)"     -- darker green text
    }

    -- Collect all styling attributes
    local size = nil
    local color = nil
    local highlight = nil
    local exambox = nil
    local is_answer = false
    local relative_size = nil
    local explicit_width = nil  -- for .wide and .narrow classes

    for _, class in ipairs(elem.classes) do
      if size_map[class] then
        size = size_map[class]
      elseif color_map[class] then
        color = color_map[class]
      elseif highlight_map[class] then
        highlight = highlight_map[class]
      elseif exambox_map[class] then
        exambox = exambox_map[class]
      elseif class == "answer" then
        is_answer = true
      elseif class == "wide" then
        explicit_width = "100%"
      elseif class == "narrow" then
        explicit_width = "narrow"  -- marker for get_width_info to use narrow width
      elseif relative_size_map[class] then
        relative_size = relative_size_map[class]
      end
    end

    -- Build the Typst code with combined styling
    -- Use #set text() to preserve structure of lists, code blocks, etc.
    if size or color or highlight or exambox or is_answer or relative_size or explicit_width then
      local result = {}
      local open_parts = {}
      local close_parts = {}

      -- When .wide is set, wrap content in force-wide-state updates so that
      -- the show rules in exam-template.typ render at full width instead of narrow width.
      if explicit_width == "100%" then
        table.insert(open_parts, "#force-wide-state.update(true)\n")
        table.insert(close_parts, "#force-wide-state.update(false)")
      end

      -- When .narrow is set, emit scoped show rules that constrain content to the
      -- narrow column width, regardless of the document-level layout mode.
      if explicit_width == "narrow" then
        table.insert(open_parts, table.concat({
          "#{\n",
          "show par: it => context block(width: exam-question-width-state.get(), it)\n",
          "show heading: it => context block(width: exam-question-width-state.get(), it)\n",
          "show enum: it => context block(width: exam-question-width-state.get(), it)\n",
          "show list: it => context block(width: exam-question-width-state.get(), it)\n",
          "[\n",
        }, ""))
        table.insert(close_parts, "]\n}")
      end

      -- Check if we need context wrapping for width
      local needs_context, width_expr = get_width_info(explicit_width)

      -- If we need context, wrap in context block and compute width
      if needs_context and (exambox or is_answer or highlight) then
        table.insert(open_parts, string.format("#context { let _w = %s;\n", width_expr))
        table.insert(close_parts, "}")
      end

      -- Apply exambox as outer wrapper if needed
      if exambox then
        -- Exambox with rounded right corners, square left, thicker left edge
        local width_val = needs_context and "_w" or width_expr
        local exambox_code = string.format(
          "block(fill: %s, stroke: (left: 3pt + %s, rest: 0.5pt + %s), radius: (top-right: 6pt, bottom-right: 6pt, rest: 0pt), inset: 10pt, width: %s)[\n",
          exambox.fill, exambox.stroke, exambox.stroke, width_val
        )
        table.insert(open_parts, exambox_code)
        table.insert(close_parts, 1, "]")
      end

      -- Apply answer styling as wrapper if needed (and not already in exambox)
      if is_answer and not exambox then
        local width_val = needs_context and "_w" or width_expr
        table.insert(open_parts, string.format("block(fill: %s, inset: 8pt, radius: 3pt, width: %s)[\n", answer_style.bg, width_val))
        table.insert(close_parts, 1, "]")
      end

      -- Apply highlight (box) as wrapper if needed (and not already in exambox or answer)
      if highlight and not exambox and not is_answer then
        local width_val = needs_context and "_w" or width_expr
        table.insert(open_parts, string.format("box(fill: %s, inset: 8pt, radius: 4pt, width: %s)[\n", highlight, width_val))
        table.insert(close_parts, 1, "]")
      end

      -- Apply text styling (size and/or color) with set rules
      if size or color or is_answer or relative_size then
        local params = {}
        if size then
          table.insert(params, string.format("size: %s", size))
        elseif relative_size then
          table.insert(params, string.format("size: %s", relative_size))
        end
        if color then
          table.insert(params, string.format("fill: %s", color))
        elseif is_answer then
          -- Apply answer text color if no other color is specified
          table.insert(params, string.format("fill: %s", answer_style.fg))
        end
        -- Open a block and use set text to change styling within the scope
        if #params > 0 then
          table.insert(open_parts, "#block[\n")
          table.insert(open_parts, string.format("#set text(%s)\n", table.concat(params, ", ")))
          table.insert(close_parts, 1, "]")
        end
      end

      -- Build result: opening code + original content + closing code
      if #open_parts > 0 then
        table.insert(result, pandoc.RawBlock("typst", table.concat(open_parts, "")))
      end

      -- Add original content blocks (preserve structure)
      for _, block in ipairs(elem.content) do
        table.insert(result, block)
      end

      -- Add closing code
      if #close_parts > 0 then
        table.insert(result, pandoc.RawBlock("typst", table.concat(close_parts, "\n")))
      end

      return result
    end
  end
  return elem
end

-- Handle inline code elements (Code) to prevent Pandoc's syntax highlighter
-- from emitting LaTeX-specific token functions (NormalTok, KeywordTok, etc.)
-- that are undefined in Typst output.
function Code(elem)
  -- Emit inline code as a raw Typst `raw` call, escaping backticks in the content
  local content = elem.text:gsub("`", "\\`")
  return pandoc.RawInline("typst", string.format("`%s`", content))
end

-- Handle fenced code blocks (CodeBlock) to prevent Pandoc's syntax highlighter
-- from emitting Typst-incompatible Skylighting/token functions.
-- We emit a plain Typst raw block, passing the language for Typst's own highlighter.
function CodeBlock(elem)
  local lang = ""
  if elem.classes and #elem.classes > 0 then
    lang = elem.classes[1]
  end
  -- Escape any backticks in the content
  local content = elem.text:gsub("`", "\\`")
  local typst_raw
  if lang ~= "" then
    typst_raw = string.format("```%s\n%s\n```", lang, content)
  else
    typst_raw = string.format("```\n%s\n```", content)
  end
  return pandoc.RawBlock("typst", typst_raw)
end

-- Process Para elements to handle shorthands in paragraph context
function Para(elem)
  -- Check if this paragraph contains only a layout shortcode
  if #elem.content == 1 and elem.content[1].t == "Str" then
    local text = elem.content[1].text
    -- Check for layout shortcodes that should be RawBlocks
    for shorthand, typst_code in pairs(shorthand_map) do
      if text == shorthand and (
        shorthand == "{{begin-narrow}}" or
        shorthand == "{{end-narrow}}" or
        shorthand == "{{begin-wide}}" or
        shorthand == "{{end-wide}}"
      ) then
        -- Convert to RawBlock instead of keeping as Para
        return pandoc.RawBlock("typst", typst_code)
      end
    end
  end

  -- Walk through all inline elements in the paragraph
  return pandoc.walk_block(elem, {
    Str = Str,
    Span = Span  -- Also process Span elements
  })
end

function Pandoc(doc)
  -- Get metadata and stringify
  local title = ""
  local subtitle = ""
  local exam_noname_str = "false"
  local exam_noinstructions_str = "false"
  local exam_titlesize = "none"
  local exam_subtitlesize = "none"
  local exam_question_display = "wide"  -- default to wide
  local exam_question_width = "2.37in"  -- default width
  local instructions = ""

  if doc.meta.title then
    title = pandoc.utils.stringify(doc.meta.title)
  end

  if doc.meta.subtitle then
    subtitle = pandoc.utils.stringify(doc.meta.subtitle)
  end

  if doc.meta["exam-noname"] then
    exam_noname_str = pandoc.utils.stringify(doc.meta["exam-noname"]):lower()
  end

  if doc.meta["exam-noinstructions"] then
    exam_noinstructions_str = pandoc.utils.stringify(doc.meta["exam-noinstructions"]):lower()
  end

  if doc.meta["exam-titlesize"] then
    exam_titlesize = pandoc.utils.stringify(doc.meta["exam-titlesize"])
  end

  if doc.meta["exam-subtitlesize"] then
    exam_subtitlesize = pandoc.utils.stringify(doc.meta["exam-subtitlesize"])
  end

  if doc.meta["exam-question-layout"] then
    exam_question_display = pandoc.utils.stringify(doc.meta["exam-question-layout"]):lower()
  end

  if doc.meta["exam-question-width"] then
    exam_question_width = pandoc.utils.stringify(doc.meta["exam-question-width"]):lower()
  end

  if doc.meta.instructions then
    instructions = pandoc.utils.stringify(doc.meta.instructions)
  end

  -- Create code to set the exam-question-layout and exam-question-width state
  -- Note: exam-question-layout is a string, but exam-question-width must be a Typst length (unquoted)
  local state_code = string.format([[#exam-question-layout-state.update("%s")
#exam-question-width-state.update(%s)
]], exam_question_display, exam_question_width)

  -- Create the exam header Typst code
  if instructions ~= "" then
    -- Escape quotes and newlines for Typst string
    instructions = instructions:gsub('"', '\\"'):gsub('\n', '\\n')
  else
    instructions = "\"\""
  end

  local header_code = string.format([[#exam-header(
  title: "%s",
  subtitle: "%s",
  titlesize: %s,
  subtitlesize: %s,
  noname: %s,
  noinstructions: %s,
  instructions: %s
)]],
    title:gsub('"', '\\"'):gsub('\n', '\\n'),
    subtitle:gsub('"', '\\"'):gsub('\n', '\\n'),
    exam_titlesize,
    exam_subtitlesize,
    exam_noname_str,
    exam_noinstructions_str,
    instructions
  )

  -- Create RawBlocks
  local state_block = pandoc.RawBlock("typst", state_code)
  local header_block = pandoc.RawBlock("typst", header_code)

  -- Insert at beginning of document; state must come before header.
  -- Insert header first (it will be at position 1 temporarily),
  -- then insert state at position 1 (pushing header to position 2).
  table.insert(doc.blocks, 1, header_block)
  table.insert(doc.blocks, 1, state_block)
  

  -- No need to wrap the document - the show rules in exam-template.typ handle it
  return doc
end

-- Explicitly define filter execution order
return {
  { Meta = Meta },  -- Process metadata first to set box_width
  { Str = Str, Span = Span, Para = Para, Div = Div, Code = Code, CodeBlock = CodeBlock },  -- Then process elements
  { Pandoc = Pandoc }  -- Finally process the whole document
}
