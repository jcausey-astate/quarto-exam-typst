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

2. Write your exam content using shortcode syntax:

```markdown
## Question 1 {{pts:10}}

Write your question here. {{ptseach:5}}

1. Part a
2. Part b

{{vf}}
```

## Custom Text Styling with Classes

The template supports Quarto's standard inline and block-level class syntax for text styling including size, color, and highlighting.

**Inline styling:**
```markdown
This is [small text]{.small} and [large red text]{.large .red} in a sentence.
You can also [highlight important text]{.highlight}.
```

**Block-level styling:**
```markdown
::: {.large}
This entire paragraph will be large.
It can span multiple lines.
:::

::: {.highlight-blue}
This creates a highlighted box with pale blue background.
:::
```

### Available Classes

**Text Sizes:**

- `.tiny` - 7pt
- `.small` - 8pt
- `.large` - 12pt
- `.huge` or `.Large` - 14pt
- `.LARGE` - 16pt

**Text Colors:**

- `.red`, `.blue`, `.green`, `.orange`, `.purple`, `.gray` (or `.grey`)

**Highlights** (pale background colors):

- `.highlight` or `.highlight-yellow` - Pale yellow background
- `.highlight-green` - Pale green background
- `.highlight-blue` - Pale blue background
- `.highlight-pink` - Pale pink background
- `.highlight-orange` - Pale orange background

**Combining Classes:**

You can combine multiple classes: `[large red text]{.large .red}` or `[highlighted and big]{.highlight .huge}`

**Practical Examples:**

```markdown
1. Mark [correct answers]{.green} and [incorrect answers]{.red}.
2. [Highlight key terms]{.highlight-yellow} in questions.
3. Use [warning text]{.orange} for important notes.

::: {.highlight-blue}
**Tip:** This creates a visually distinct instruction box.
:::
```

All classes work with both inline spans `[text]{.classname}` and block divs `::: {.classname}`. You can easily extend the Lua filter in `templates/exam-typst/_filters/exam-auto-header.lua` to add more custom styling options.

## Available Shortcodes

The template includes a Lua filter that provides convenient shortcode syntax for common exam elements. All shortcodes use the `{{keyword}}` or `{{keyword:parameter}}` format.

### Parameterized Shortcodes

**Point Values:**

- `{{pts:N}}` - Displays point value (e.g., `{{pts:10}}` renders as "(10 pts)")
- `{{ptseach:N}}` - Displays point value per item (e.g., `{{ptseach:5}}` renders as "(5 pts each)")

**Examples:**

```markdown
## Part 1: Multiple Choice {{pts:20}}

Choose the best answer. {{ptseach:4}}

1. {{pts:4}} What is the time complexity of binary search?
```

### Simple Shortcodes (No Parameters)

**Spacing & Page Breaks:**

- `{{vf}}` - Vertical fill (expands to fill available space)
- `{{pagebreak}}` - Page break

**Answer Blanks** (render inline with text):

- `{{sblank}}` - Small blank line (1.5em): ___
- `{{ssblank}}` - Super small blank with "?" (0.5em ? 0.5em): _?_
- `{{lblank}}` - Large blank line (10em): __________
- `{{blank}}` - Alias for `{{ssblank}}`

**Inline blank usage example:**

```markdown
The velocity is {{sblank}} m/s and the temperature is {{ssblank}} degrees.
```

This renders as: "The velocity is ___ m/s and the temperature is _?_ degrees."

**Layout Modes:**

- `{{begin-narrow}}` ... `{{end-narrow}}` - Narrow layout with right column blank for handwritten answers
- `{{begin-wide}}` ... `{{end-wide}}` - Full-width layout

The behavior of these layout blocks depends on the `exam-question-width` parameter:

- **When `exam-question-width: wide` (default):** The page defaults to full width. Use `{{begin-narrow}}...{{end-narrow}}` blocks to create constrained sections for handwritten answers.
- **When `exam-question-width: narrow`:** The page defaults to narrow width (left column only). Use `{{begin-wide}}...{{end-wide}}` blocks to create full-width sections for diagrams, tables, or questions needing more space.

**Layout example (wide mode - default):**

```markdown
{{begin-narrow}}

Answer the following in the space provided to the right.

1. {{pts:5}} Calculate: 42 × 17

{{vf}}

2. {{pts:5}} Solve for x: 3x - 7 = 14

{{vf}}

{{end-narrow}}
```

**Layout example (narrow mode):**

```markdown
---
exam-question-width: narrow
---

This content appears in narrow mode by default.

1. {{pts:5}} Calculate: 42 × 17

{{vf}}

{{begin-wide}}

This section expands to full width for a diagram or table.

{{end-wide}}

Back to narrow mode for more questions.
```

### Alternative: Direct Typst Syntax

If you prefer explicit Typst syntax, you can still use the backtick-wrapped format:

**Point Values:**
- `` `#pts([N])`{=typst} `` - Adds a superscript point value (e.g., "(10 pt.)")
- `` `#ptseach([N])`{=typst} `` - Adds a superscript point value for multiple items (e.g., "(5 pt. each)")

**Answer Blanks:**
- `` `#blank()`{=typst} `` - Small blank with question mark
- `` `#ssblank()`{=typst} `` - Small blank with question mark (same as blank)
- `` `#sblank()`{=typst} `` - Short blank line
- `` `#lblank()`{=typst} `` - Long blank line

**Spacing:**
- `` `#vf()`{=typst} `` - Vertical fill (expands to fill available space)
- `` `#pagebreak()`{=typst} `` - Page break

**Layout Modes:**
- `` `#wide([content])`{=typst} `` - Full-width layout (default)
- `` `#narrow([content])`{=typst} `` - Narrow layout with right column blank for handwritten answers (default left column width: 2.37in)
- `` `#narrow(columnwidth: 3in, [content])`{=typst} `` - Custom left column width

The narrow mode constrains content to the left column, leaving the right side blank for students to write answers. Content can naturally overflow into the answer area if needed (e.g., wide figures).

## Exam Header Options

Configure the exam header using these YAML frontmatter variables:

- `title` - Exam title (string)
- `subtitle` - Exam subtitle (string)
- `exam-titlesize` - Title font size (default: 20pt)
- `exam-subtitlesize` - Subtitle font size (default: 14pt)
- `exam-noname` - Hide the name field (default: false)
- `exam-noinstructions` - Hide the instructions (default: false)
- `exam-question-width` - Default question width mode: "wide" or "narrow" (default: "wide")

Example:
```yaml
title: "Data Structures Final Exam"
subtitle: "Spring 2025"
exam-noname: false
exam-noinstructions: false
exam-titlesize: 20pt
exam-subtitlesize: 14pt
exam-question-width: narrow
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

If you're migrating from the LaTeX template, use these shortcode equivalents:

| LaTeX Command | Recommended Shortcode | Alternative Typst Syntax |
|---------------|----------------------|--------------------------|
| `\pts{N}` | `{{pts:N}}` | `` `#pts([N])`{=typst} `` |
| `\ptseach{N}` | `{{ptseach:N}}` | `` `#ptseach([N])`{=typst} `` |
| `\blank` | `{{blank}}` or `{{ssblank}}` | `` `#blank()`{=typst} `` |
| `\sblank` | `{{sblank}}` | `` `#sblank()`{=typst} `` |
| `\lblank` | `{{lblank}}` | `` `#lblank()`{=typst} `` |
| `\vf` | `{{vf}}` | `` `#vf()`{=typst} `` |
| `\pagebreak` | `{{pagebreak}}` | `` `#pagebreak()`{=typst} `` |
| `\wide` | `{{begin-wide}}` ... `{{end-wide}}` | `` `#wide([content])`{=typst} `` |
| `\narrow` | `{{begin-narrow}}` ... `{{end-narrow}}` | `` `#narrow([content])`{=typst} `` |

### Notes on Migration

- **Shortcodes**: The new shortcode syntax (`{{keyword}}` and `{{keyword:N}}`) is cleaner and easier to read than the verbose Typst syntax
- **Inline Blanks**: Blank shortcodes now render properly inline with text (this was fixed to match LaTeX behavior)
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
