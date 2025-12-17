# Quarto Typst Exam Template

This is a Quarto Typst template for creating exam papers.

It supports two layout modes: **wide mode** (full-width, default) for sections without handwritten answers, and **narrow mode** where questions are in a narrow left column to allow room for handwritten answers on the right.

The template includes helper features for common exam tasks: point values, answer blanks, styled boxes, answer keys, and more.

Of course, all of Quarto's built-in Markdown extensions, shortcodes, etc. are at your disposal as well.

## Files

- `_extensions/exam/typst-template.typ` - Helper functions for exams (points, blanks, vertical fill)
- `_extensions/exam/typst-show.typ` - Document formatting (no page numbers, heading styles)
- `_extensions/exam/exam-header.typ` - Exam header generator (title, subtitle, name field, instructions)
- `_extensions/exam/_filters/exam-auto-header.lua` - Lua filter that auto-generates exam header from YAML metadata
- `example-exam.qmd` - Example exam demonstrating common features

## Quick Start

1. **Install the template** by creating a new Quarto project:

   ```bash
   quarto use template jcausey/quarto-typst-exam-template
   ```

   Or add it to an existing project:

   ```bash
   quarto add jcausey/quarto-typst-exam-template
   ```

2. **Create your exam** in a `.qmd` file:

   ```yaml
   ---
   title: "Your Exam Title"
   subtitle: "Your Subtitle"
   format: exam-typst
   ---
   ```

3. **Write your exam content** using shortcode syntax:

   ```markdown
   @. {{pts:5}} Your question here.

   @. {{ptseach:5}} Here is a question with parts:
     a) Part a
     b) Part b

   {{vf}}
   ```

4. **Render your exam** to PDF:

   ```bash
   quarto render your-exam.qmd
   ```

## Quick Reference

Common shortcodes you'll use most often:

| Shortcode | Description | Example |
|-----------|-------------|---------|
| `{{pts:N}}` | Point value for a question | `{{pts:10}}` → "(10 pts)" |
| `{{ptseach:N}}` | Point value for each item | `{{ptseach:5}}` → "(5 pts each)" |
| `{{vf}}` | Vertical fill (expands to fill space) | Use after questions needing answer space |
| `{{begin-narrow}}` ... `{{end-narrow}}` | Narrow layout for handwritten answers | Wrap sections needing answer space |
| `{{begin-wide}}` ... `{{end-wide}}` | Full-width layout | Use when `exam-question-display: narrow` |
| `{{sblank}}` | Small blank line | `{{sblank}}` → ___ |
| `{{lblank}}` | Large blank line | `{{lblank}}` → __________ |

## Core Exam Features

### Point Values

Add point values to questions and sections using shortcodes:

- `{{pts:N}}` - Displays point value (e.g., `{{pts:10}}` renders as "(10 pts)")
- `{{ptseach:N}}` - Displays point value per item (e.g., `{{ptseach:5}}` renders as "(5 pts each)")

**Examples:**

```markdown
## Part 1: Multiple Choice {{pts:20}}

Choose the best answer. {{ptseach:4}}

1. {{pts:4}} What is the time complexity of binary search?
```

### Answer Blanks

Create inline blanks for fill-in-the-blank questions:

- `{{sblank}}` - Small blank line (1.5em): ___
- `{{lblank}}` - Large blank line (10em): __________
- `{{ssblank}}` or `{{blank}}` - Super small blank with "?": \_?\_

**Example:**

```markdown
The time complexity of binary search is {{sblank}} and it requires a {{sblank}} array.
```

This renders as: "The time complexity of binary search is ___ and it requires a ___ array."

### Layout Modes: Wide vs Narrow

The template supports two layout modes that can be mixed within the same exam:

**Wide Mode (Default):** Full-width layout for questions that don't need handwritten answer space.

**Narrow Mode:** Questions in a narrow left column with blank space on the right for handwritten answers.

**Controlling the default mode:**

Set the default in your YAML frontmatter:

```yaml
---
exam-question-display: wide    # Default: full-width layout
# OR
exam-question-display: narrow  # Default: narrow layout with answer space
exam-question-width: 3.27in     # Width of question column in narrow mode
---
```

**Switching modes within your exam:**

- When `exam-question-display: wide` (default), use `{{begin-narrow}}...{{end-narrow}}` to create sections with answer space
- When `exam-question-display: narrow`, use `{{begin-wide}}...{{end-wide}}` to create full-width sections

**Example (using default wide mode with a narrow section):**

```markdown
---
format: exam-typst
---

## Part 1: Multiple Choice {{pts:20}}

These questions are full-width (no writing space needed).

1. What is 2 + 2?
   a) 3  b) 4  c) 5

{{begin-narrow}}

## Part 2: Short Answer {{pts:30}}

These questions have writing space on the right.

1. {{pts:10}} Explain the concept of recursion.

{{vf}}

2. {{pts:20}} Describe three sorting algorithms.

{{vf}}
{{vf}}

{{end-narrow}}
```

### Vertical Fill

Use `{{vf}}` to create flexible vertical space that expands to fill available room. This is useful for giving students space to write answers:

```markdown
1. {{pts:10}} Solve the following problem:

{{vf}}

2. {{pts:10}} Show your work:

{{vf}}
{{vf}}  # Use multiple {{vf}} for more space
```

## Styling Features

### Custom Text Styling with Classes

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

**Layout Width Classes:**

The `.wide` and `.narrow` classes control the width of block-level elements (examboxes, answer blocks, and highlights). These override automatic width detection:

- `.wide` - Forces full width (100%) regardless of current layout mode
- `.narrow` - Forces narrow width (uses `exam-question-width` setting)

These are useful when you want explicit control over box width:

```markdown
::: {.exambox-blue .wide}
This exambox will be full width even inside a narrow section.
:::

::: {.answer .narrow}
This answer block will be narrow width even inside a wide section.
:::
```

Without these classes, boxes automatically adapt to their context: full width in wide sections, narrow in narrow sections.

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

**Automatic Width Adaptation:** Examboxes automatically adapt their width to the current layout context. In narrow sections (or when `exam-question-display: narrow`), they use the width specified by `exam-question-width`. In wide sections, they use full width. Use `.wide` or `.narrow` classes to override this behavior.

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

**Automatic Width Adaptation:** Answer blocks automatically adapt their width to the current layout context. In narrow sections (or when `exam-question-display: narrow`), they use the width specified by `exam-question-width`. In wide sections, they use full width. Use `.wide` or `.narrow` classes to override this behavior.

You can easily extend the Lua filter in `_extensions/exam/_filters/exam-auto-header.lua` to add more custom styling options.

## Advanced: Direct Typst Syntax

If you prefer explicit Typst syntax over shortcodes, you can use the backtick-wrapped format:

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
- `instructions` - Custom exam instructions (string). If not specified, default instructions are used.
- `exam-question-display` - Default question display style: "wide" or "narrow" (default: "wide")
- `exam-question-width` - Specific width of question column when in "narrow" question style. (No effect when in "wide" display style.)

### Custom Instructions

By default, exams display these instructions:

> Read each question carefully and fully before answering. Answer all questions using complete sentences unless the question specifies otherwise. Explain your thoughts and provide any necessary context; supporting examples, code, formulas, etc. are encouraged. Clearly state any additional assumptions you make in forming your responses; always be as specific as possible.

To use custom instructions, add an `instructions` field to your YAML frontmatter:

```yaml
instructions: "Answer all questions completely. Show all work. You may use your notes and textbook."
```

### Example Configuration

```yaml
title: "Data Structures Final Exam"
subtitle: "Spring 2025"
exam-noname: false
exam-noinstructions: false
instructions: "Answer all questions in the spaces provided. You may use a calculator but not other resources."
exam-titlesize: 20pt
exam-subtitlesize: 14pt
exam-question-display: narrow
exam-question-width: 3.5in
```

## Example

See `example-exam.qmd` for a complete working example.

## Customization

You can customize the appearance by:

1. Modifying `_extensions/exam/typst-template.typ` to change helper functions
2. Modifying `_extensions/exam/typst-show.typ` to change document-wide formatting
3. Modifying `_extensions/exam/exam-header.typ` to change header appearance
4. Adjusting margins and fonts in the YAML frontmatter


## MIT License
Copyright 2025 Jason L Causey, Arkansas State University

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
