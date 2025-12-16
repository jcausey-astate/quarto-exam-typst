# Quarto Typst Exam Template

This is a Quarto typst template for creating exam papers.  

It supports a "normal" (we call it "wide") mode where questions go edge-to-edge, and a "narrow" mode where questions are in a narrow column on the left to allow room for answers to the right.

There are also many helper features for performing formatting tasks that are helpful for paper exams.

Of course, all of Quarto's built-in Markdown extensions, shortcode, etc. are at your disposal as well.

## Files

- `templates/exam-typst/typst-template.typ` - Helper functions for exams (points, blanks, vertical fill)
- `templates/exam-typst/typst-show.typ` - Document formatting (no page numbers, heading styles)
- `templates/exam-typst/exam-header.typ` - Exam header generator (title, subtitle, name field, instructions)
- `templates/exam-typst/_filters/exam-auto-header.lua` - Lua filter that auto-generates exam header from YAML metadata
- `example-exam.qmd` - Example exam demonstrating common features

## Quick Start

1. Create a `.qmd` file with the following frontmatter:

```yaml
---
title: "Your Exam Title"
subtitle: "Your Subtitle"
exam-noname: false
exam-noinstructions: false
exam-titlesize: 14pt
exam-subtitlesize: 12pt
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
@. {{pts:5}} Your question here.

@. {{ptseach:5}} Here is a question with parts:
  a) Part a
  b) Part b

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

**Text Sizes:**  These size classes are designed to be similar to LaTeX.

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

You can combine multiple classes in any order to apply multiple styling effects:

- Size + Color: `[large red text]{.large .red}`
- Size + Highlight: `[small highlighted]{.small .highlight-green}`
- Color + Highlight: `[blue text on yellow]{.blue .highlight-yellow}`
- All three: `[large red highlighted]{.large .red .highlight}`

The order doesn't matter - `[text]{.red .large}` and `[text]{.large .red}` produce the same result.

**Nesting Spans:**

Spans can be nested arbitrarily deep. The styling is properly preserved:

```markdown
[Outer large text with [nested red]{.red} inside]{.large}

[*Requirements:*
★ Must modify in-place ([O(1) space]{.blue})
★ Must run in O(n) time]{.small}
```

Each nested span retains its own styling while being contained within the outer span's styling.

**Practical Examples:**

```markdown
1. Mark [correct answers]{.green} and [incorrect answers]{.red}.
2. [Highlight key terms]{.highlight-yellow} in questions.
3. Use [warning text]{.orange} for important notes.

::: {.highlight-blue}
**Tip:** This creates a visually distinct instruction box.
:::
```

All classes work with both inline spans `[text]{.classname}` and block divs `::: {.classname}`. Block-level styling preserves the structure of lists, code blocks, and nested divs within the styled content.

### Exambox (Styled Callout Boxes)

The template provides `.exambox` classes for creating visually distinct boxes with colored backgrounds. These are useful for example problems, parenthetical notes, or important instructions.

**Available Exambox Styles:**

- `.exambox` or `.exambox-blue` - Light blue background with blue border
- `.exambox-green` - Light green background with green border
- `.exambox-yellow` - Light yellow background with yellow border
- `.exambox-red` - Light red background with red border
- `.exambox-orange` - Light orange background with orange border
- `.exambox-gray` - Light gray background with gray border

**Usage:**

```markdown
::: {.exambox-green}
**Example Problem:** Calculate the following:

- What is 2 + 2?
- What is 5 × 3?
- What is 10 ÷ 2?
:::
```

Examboxes support full content including lists, code blocks, and nested formatting.

**Note:** When using `exam-question-display: narrow`, examboxes automatically constrain to the width specified by `exam-question-width` to align with other content in the left column.

### Answer Styling

The `.answer` class provides subtle styling for marking answers in exams, with a light green background and darker green text.

**Usage:**

Inline answers:
```markdown
What is 2 + 2? [The answer is 4]{.answer}

Who wrote "Hamlet"? [William Shakespeare]{.answer}
```

Block-level answers:
```markdown
::: {.answer}
**Sample Solution:**

Recursion is a programming technique where a function calls itself. It has:

1. A base case that stops the recursion
2. A recursive case that calls itself with modified arguments
:::
```

Answer blocks preserve the structure of lists, code blocks, and other formatting within them.

**Note:** When using `exam-question-display: narrow`, answer blocks automatically constrain to the width specified by `exam-question-width` to align with other content in the left column.

You can easily extend the Lua filter in `templates/exam-typst/_filters/exam-auto-header.lua` to add more custom styling options.

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

**Answer Blanks** (render inline with text):

- `{{sblank}}` - Small blank line (1.5em): ___
- `{{ssblank}}` - Super small blank with "?" (0.5em ? 0.5em): _?_
- `{{lblank}}` - Large blank line (10em): __________
- `{{blank}}` - Alias for `{{ssblank}}`

**Inline blank usage example:**

```markdown
The velocity is {{sblank}} m/s and the temperature is {{ssblank}} degrees.
```

This renders as: "The velocity is ___ m/s and the temperature is \_?\_ degrees."

**Layout Modes:**

- `{{begin-narrow}}` ... `{{end-narrow}}` - Narrow layout with right column blank for handwritten answers
- `{{begin-wide}}` ... `{{end-wide}}` - Full-width layout

The behavior of these layout blocks depends on the `exam-question-display` parameter:

- **When `exam-question-display: wide` (default):** The page defaults to full width. Use `{{begin-narrow}}...{{end-narrow}}` blocks to create constrained sections for handwritten answers.
- **When `exam-question-display: narrow`:** The page defaults to narrow width (left column only). Use `{{begin-wide}}...{{end-wide}}` blocks to create full-width sections for diagrams, tables, or questions needing more space.

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
exam-question-display: narrow
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
- `exam-question-display` - Default question display style: "wide" or "narrow" (default: "wide")
- `exam-question-width` - Specific width of question column when in "narrow" question style. (No effect when in "wide" display style.)

Example:
```yaml
title: "Data Structures Final Exam"
subtitle: "Spring 2025"
exam-noname: false
exam-noinstructions: false
exam-titlesize: 20pt
exam-subtitlesize: 14pt
exam-question-display: narrow
exam-question-width: 3.5in
```

## Example

See `example-exam.qmd` for a complete working example.

## Rendering

Render your exam with:

```bash
quarto render your-exam.qmd
```

This will generate a PDF file with your exam.

## Customization

You can customize the appearance by:

1. Modifying `templates/exam-typst/typst-template.typ` to change helper functions
2. Modifying `templates/exam-typst/typst-show.typ` to change document-wide formatting
3. Modifying `templates/exam-typst/exam-header.typ` to change header appearance
4. Adjusting margins and fonts in the YAML frontmatter


## MIT License
Copyright 2025 Jason L Causey, Arkansas State University

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
