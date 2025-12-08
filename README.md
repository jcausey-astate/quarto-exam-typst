# Quarto Typst Exam Template

This is a Quarto typst template for creating exam papers, converted from the original LaTeX template.

## Files

- `templates/exam-typst/typst-template.typ` - Helper functions for exams (points, blanks, vertical fill)
- `templates/exam-typst/typst-show.typ` - Document formatting (no page numbers, heading styles)
- `templates/exam-typst/exam-header.typ` - Exam header generator (title, subtitle, name field, instructions)
- `templates/exam-typst/_filters/exam-auto-header.lua` - Lua filter that auto-generates exam header from YAML metadata
- `example-exam.qmd` - Example exam demonstrating all features

## Quick Start

1. Create a `.qmd` file with the following frontmatter:

```yaml
---
title: "Your Exam Title"
subtitle: "Semester Year"
exam-noname: false
exam-noinstructions: false
exam-titlesize: 20pt
exam-subtitlesize: 14pt
format:
  typst:
    papersize: us-letter
    margin:
      x: 2cm
      y: 2cm
    mainfont: "Times New Roman"
    fontsize: 10pt
    keep-typ: false
    template-partials:
      - templates/exam-typst/typst-template.typ
      - templates/exam-typst/typst-show.typ
filters:
  - templates/exam-typst/_filters/exam-auto-header.lua
---
```

2. Write your exam content directly - the header is generated automatically:

```markdown
## Question 1 `#pts([10])`{=typst}

Write your question here. `#ptseach([5])`{=typst}

1. Part a
2. Part b

`#vf()`{=typst}
```

## Available Functions

### Point Values
- `` `#pts([N])`{=typst} `` - Adds a superscript point value (e.g., "(10 pt.)")
- `` `#ptseach([N])`{=typst} `` - Adds a superscript point value for multiple items (e.g., "(5 pt. each)")

### Answer Blanks
- `` `#blank()`{=typst} `` - Small blank with question mark
- `` `#ssblank()`{=typst} `` - Small blank with question mark (same as blank)
- `` `#sblank()`{=typst} `` - Short blank line
- `` `#lblank()`{=typst} `` - Long blank line

### Spacing
- `` `#vf()`{=typst} `` - Vertical fill (expands to fill available space)
- `` `#pagebreak()`{=typst} `` - Page break

### Layout Modes
- `` `#wide([content])`{=typst} `` - Full-width layout (default)
- `` `#narrow([content])`{=typst} `` - Narrow layout with right column blank for handwritten answers
- `` `#narrow(answerwidth: 3in, [content])`{=typst} `` - Custom answer column width (default: 2.37in)

The narrow mode constrains content to the left side of the page, leaving the right side blank for students to write answers. Content can naturally overflow into the answer area if needed (e.g., wide figures).

## Exam Header Options

Configure the exam header using these YAML frontmatter variables:

- `title` - Exam title (string)
- `subtitle` - Exam subtitle (string)
- `exam-titlesize` - Title font size (default: 20pt)
- `exam-subtitlesize` - Subtitle font size (default: 14pt)
- `exam-noname` - Hide the name field (default: false)
- `exam-noinstructions` - Hide the instructions (default: false)

Example:
```yaml
title: "Data Structures Final Exam"
subtitle: "Spring 2025"
exam-noname: false
exam-noinstructions: false
exam-titlesize: 20pt
exam-subtitlesize: 14pt
```

## Example

See `example-exam.qmd` for a complete working example.

## Rendering

Render your exam with:

```bash
quarto render your-exam.qmd
```

This will generate a PDF file with your exam.

## Migration from LaTeX Template

If you're migrating from the LaTeX template:

| LaTeX Command | Typst Equivalent |
|---------------|------------------|
| `\pts{N}` | `` `#pts([N])`{=typst} `` |
| `\ptseach{N}` | `` `#ptseach([N])`{=typst} `` |
| `\blank` | `` `#blank()`{=typst} `` |
| `\sblank` | `` `#sblank()`{=typst} `` |
| `\lblank` | `` `#lblank()`{=typst} `` |
| `\vf` | `` `#vf()`{=typst} `` |
| `\pagebreak` | `` `#pagebreak()`{=typst} `` |
| `\wide` | `` `#wide([content])`{=typst} `` |
| `\narrow` | `` `#narrow([content])`{=typst} `` |

### Notes on Migration

- **Functions**: All custom functions must be called using `` `#function()`{=typst} `` syntax
- **Unicode**: Typst has excellent built-in Unicode support, so no special setup is needed for symbols and emoji
- **Code Highlighting**: Quarto handles syntax highlighting automatically for code blocks

## Customization

You can customize the appearance by:

1. Modifying `templates/exam-typst/typst-template.typ` to change helper functions
2. Modifying `templates/exam-typst/typst-show.typ` to change document-wide formatting
3. Modifying `templates/exam-typst/exam-header.typ` to change header appearance
4. Adjusting margins and fonts in the YAML frontmatter

## Known Limitations

Currently no known limitations. All LaTeX template features have been ported to Typst.
