-- Auto-generate exam header from YAML metadata
-- Also provides shorthand syntax for common Typst exam functions

-- Default mapping of shorthand syntax to Typst code (when exam-question-width is "wide" or unset)
local default_shorthand_map = {
  ["{{vf}}"] = "#vf()",
  ["{{sblank}}"] = "#sblank()",
  ["{{blank}}"] = "#blank()",
  ["{{ssblank}}"] = "#ssblank()",
  ["{{lblank}}"] = "#lblank()",
  ["{{pagebreak}}"] = "#pagebreak()",
  ["{{begin-narrow}}"] = "#narrow([",
  ["{{end-narrow}}"] = "])",
  ["{{begin-wide}}"] = "#wide([",
  ["{{end-wide}}"] = "])",
}

-- This will be set based on exam-question-width parameter
local shorthand_map = default_shorthand_map

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

    -- Collect all styling attributes
    local size = nil
    local color = nil
    local highlight = nil

    for _, class in ipairs(elem.classes) do
      if size_map[class] then
        size = size_map[class]
      elseif color_map[class] then
        color = color_map[class]
      elseif highlight_map[class] then
        highlight = highlight_map[class]
      end
    end

    -- Build the Typst code with combined styling
    if size or color or highlight then
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

      -- Apply highlight (box) on top if needed
      if highlight then
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

    local content = pandoc.utils.stringify(elem.content)

    -- Collect all styling attributes
    local size = nil
    local color = nil
    local highlight = nil

    for _, class in ipairs(elem.classes) do
      if size_map[class] then
        size = size_map[class]
      elseif color_map[class] then
        color = color_map[class]
      elseif highlight_map[class] then
        highlight = highlight_map[class]
      end
    end

    -- Build the Typst code with combined styling
    if size or color or highlight then
      local result = content

      -- Apply text styling (size and/or color) first
      if size or color then
        local params = {}
        if size then
          table.insert(params, string.format("size: %s", size))
        end
        if color then
          table.insert(params, string.format("fill: %s", color))
        end
        result = string.format("#text(%s)[\n%s\n]", table.concat(params, ", "), result)
      end

      -- Apply highlight (box) on top if needed
      if highlight then
        result = string.format("#box(fill: %s, inset: 8pt, radius: 4pt, width: 100%%)[\n%s\n]",
          highlight, result)
      end

      return pandoc.RawBlock("typst", result)
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
  local exam_question_width = "wide"  -- default to wide for backwards compatibility

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

  if doc.meta["exam-question-width"] then
    exam_question_width = pandoc.utils.stringify(doc.meta["exam-question-width"]):lower()
  end

  -- The shorthand_map is always the same now - the Typst functions handle mode logic
  shorthand_map = default_shorthand_map

  -- Create code to set the exam-question-width state
  local state_code = string.format([[#exam-question-width-state.update("%s")
]], exam_question_width)

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
