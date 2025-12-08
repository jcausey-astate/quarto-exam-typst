-- Auto-generate exam header from YAML metadata
-- Also provides shorthand syntax for common Typst exam functions

-- Mapping of shorthand syntax to Typst code
local shorthand_map = {
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

-- Escape special characters for pattern matching
local function escape_pattern(text)
  return text:gsub("[%-%.%+%*%?%[%]%(%)%^%$%%]", "%%%1")
end

-- Process Str elements (plain text) - this is where inline text gets processed
function Str(elem)
  -- Check if this string contains any shorthand
  for shorthand, typst_code in pairs(shorthand_map) do
    if elem.text:find(escape_pattern(shorthand), 1, true) then
      -- Split the text around the shorthand and create a list of inlines
      local result = {}
      local remaining = elem.text

      while remaining ~= "" do
        local start_pos, end_pos = remaining:find(escape_pattern(shorthand), 1, true)
        if start_pos then
          -- Add text before the shorthand
          if start_pos > 1 then
            table.insert(result, pandoc.Str(remaining:sub(1, start_pos - 1)))
          end
          -- Add the Typst code as inline raw
          table.insert(result, pandoc.RawInline("typst", typst_code))
          -- Continue with remaining text
          remaining = remaining:sub(end_pos + 1)
        else
          -- No more shorthands, add remaining text
          if remaining ~= "" then
            table.insert(result, pandoc.Str(remaining))
          end
          break
        end
      end

      return result
    end
  end

  return elem
end

-- Process Para elements to handle shorthands in paragraph context
function Para(elem)
  -- Walk through all inline elements in the paragraph
  return pandoc.walk_block(elem, {
    Str = Str
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

  -- Create a RawBlock of typst code
  local header_block = pandoc.RawBlock("typst", header_code)

  -- Insert at beginning of document
  table.insert(doc.blocks, 1, header_block)

  return doc
end
