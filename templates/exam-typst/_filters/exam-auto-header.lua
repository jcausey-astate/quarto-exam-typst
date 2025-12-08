-- Auto-generate exam header from YAML metadata
-- Also provides shorthand syntax for common Typst exam functions

-- Mapping of shorthand syntax to Typst code
local shorthand_replacements = {
  ["{{vf}}"] = "`#vf()`{=typst}",
  ["{{sblank}}"] = "`#sblank()`{=typst}",
  ["{{blank}}"] = "`#blank()`{=typst}",
  ["{{ssblank}}"] = "`#ssblank()`{=typst}",
  ["{{lblank}}"] = "`#lblank()`{=typst}",
  ["{{pagebreak}}"] = "`#pagebreak()`{=typst}",
  ["{{begin-narrow}}"] = "`#narrow([`{=typst}",
  ["{{end-narrow}}"] = "`])`{=typst}",
  ["{{begin-wide}}"] = "`#wide([`{=typst}",
  ["{{end-wide}}"] = "`])`{=typst}",
}

-- Replace shorthand in text
local function replace_shorthand(text)
  for shorthand, replacement in pairs(shorthand_replacements) do
    text = text:gsub(shorthand:gsub("[%-%.%+%*%?%[%]%(%)%^%$%%]", "%%%1"), replacement)
  end
  return text
end

-- Process Str elements (plain text)
function Str(elem)
  local newtext = replace_shorthand(elem.text)
  if newtext ~= elem.text then
    -- If text was replaced, we need to parse it as markdown to get inline elements
    return pandoc.read(newtext, "markdown").blocks[1].content
  end
  return elem
end

-- Process inline elements (for text within paragraphs)
function RawInline(elem)
  if elem.format == "html" or elem.format == "markdown" then
    elem.text = replace_shorthand(elem.text)
  end
  return elem
end

-- Process block elements (for standalone text)
function RawBlock(elem)
  if elem.format == "html" or elem.format == "markdown" then
    elem.text = replace_shorthand(elem.text)
  end
  return elem
end

-- Process code blocks that are plain text
function CodeBlock(elem)
  elem.text = replace_shorthand(elem.text)
  return elem
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
