-- Auto-generate exam header from YAML metadata

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
