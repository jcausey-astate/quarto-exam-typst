-- Auto-generate exam header from YAML metadata
-- Also provides shorthand syntax for common Typst exam functions

-- Default mapping of shorthand syntax to Typst code (when exam-question-display is "wide" or unset)
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

-- This will be set based on exam-question-display parameter
local box_width = "100%"  -- boxes default to full width; narrow mode changes this

-- Process metadata first to set box_width before processing document elements
function Meta(meta)
  -- Get exam-question-display and exam-question-width from metadata
  local exam_question_display = "wide"  -- default
  local exam_question_width = "2.37in"  -- default

  if meta["exam-question-display"] then
    exam_question_display = pandoc.utils.stringify(meta["exam-question-display"]):lower()
  end

  if meta["exam-question-width"] then
    exam_question_width = pandoc.utils.stringify(meta["exam-question-width"]):lower()
  end

  -- Set box_width based on display mode
  if exam_question_display == "narrow" then
    box_width = exam_question_width
  end

  return meta
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
    local size_map = {
      ["tiny"] = "7pt",
      ["small"] = "8pt",
      ["large"] = "12pt",
      ["huge"] = "14pt",
      ["Large"] = "14pt",  -- alternative
      ["LARGE"] = "16pt",
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

    for _, class in ipairs(elem.classes) do
      if size_map[class] then
        size = size_map[class]
      elseif color_map[class] then
        color = color_map[class]
      elseif highlight_map[class] then
        highlight = highlight_map[class]
      elseif class == "answer" then
        is_answer = true
      end
    end

    -- Build the Typst code with combined styling
    if size or color or highlight or is_answer then
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
      if size or color then
        local params = {}
        if size then
          table.insert(params, string.format("size: %s", size))
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
  -- Check if div has classes
  if #elem.classes > 0 then
    -- Map class names to Typst text sizes
    local size_map = {
      ["tiny"] = "7pt",
      ["small"] = "8pt",
      ["large"] = "12pt",
      ["huge"] = "14pt",
      ["Large"] = "14pt",  -- alternative
      ["LARGE"] = "16pt",
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
      end
    end

    -- Build the Typst code with combined styling
    -- Use #set text() to preserve structure of lists, code blocks, etc.
    if size or color or highlight or exambox or is_answer then
      local result = {}
      local open_parts = {}
      local close_parts = {}

      -- Apply exambox as outer wrapper if needed
      if exambox then
        -- Exambox with rounded right corners, square left, thicker left edge
        local exambox_code = string.format(
          "#block(fill: %s, stroke: (left: 3pt + %s, rest: 0.5pt + %s), radius: (top-right: 6pt, bottom-right: 6pt, rest: 0pt), inset: 10pt, width: %s)[\n",
          exambox.fill, exambox.stroke, exambox.stroke, box_width
        )
        table.insert(open_parts, exambox_code)
        table.insert(close_parts, 1, "]")
      end

      -- Apply answer styling as wrapper if needed (and not already in exambox)
      if is_answer and not exambox then
        table.insert(open_parts, string.format("#block(fill: %s, inset: 8pt, radius: 3pt, width: %s)[\n", answer_style.bg, box_width))
        table.insert(close_parts, 1, "]")
      end

      -- Apply highlight (box) as wrapper if needed (and not already in exambox or answer)
      if highlight and not exambox and not is_answer then
        table.insert(open_parts, string.format("#box(fill: %s, inset: 8pt, radius: 4pt, width: %s)[\n", highlight, box_width))
        table.insert(close_parts, 1, "]")
      end

      -- Apply text styling (size and/or color) with set rules
      if size or color or is_answer then
        local params = {}
        if size then
          table.insert(params, string.format("size: %s", size))
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
  local exam_titlesize = "20pt"
  local exam_subtitlesize = "14pt"
  local exam_question_display = "wide"  -- default to wide
  local exam_question_width = "2.37in"  -- default width

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

  if doc.meta["exam-question-display"] then
    exam_question_display = pandoc.utils.stringify(doc.meta["exam-question-display"]):lower()
  end

  if doc.meta["exam-question-width"] then
    exam_question_width = pandoc.utils.stringify(doc.meta["exam-question-width"]):lower()
  end

  -- Create code to set the exam-question-display and exam-question-width state
  local state_code = string.format([[#exam-question-display-state.update("%s")
#exam-question-width-state.update("%s")
]], exam_question_display, exam_question_width)

  -- Create the exam header Typst code
  local header_code = string.format([[#import "templates/exam-typst/exam-header.typ": exam-header
#exam-header(
  title: "%s",
  subtitle: "%s",
  titlesize: %s,
  subtitlesize: %s,
  noname: %s,
  noinstructions: %s,
)]],
    title:gsub('"', '\\"'):gsub('\n', '\\n'),
    subtitle:gsub('"', '\\"'):gsub('\n', '\\n'),
    exam_titlesize,
    exam_subtitlesize,
    exam_noname_str,
    exam_noinstructions_str
  )

  -- Create RawBlocks
  local state_block = pandoc.RawBlock("typst", state_code)
  local header_block = pandoc.RawBlock("typst", header_code)

  -- Insert at beginning of document
  table.insert(doc.blocks, 1, header_block)
  table.insert(doc.blocks, 1, state_block)  -- state must come before header

  -- No need to wrap the document - the show rules in typst-show.typ handle it

  return doc
end

-- Explicitly define filter execution order
return {
  { Meta = Meta },  -- Process metadata first to set box_width
  { Str = Str, Span = Span, Para = Para, Div = Div },  -- Then process elements
  { Pandoc = Pandoc }  -- Finally process the whole document
}
