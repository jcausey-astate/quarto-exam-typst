// Quarto Typst Exam Template
// Helper functions and definitions for exam documents

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Point value functions
#let pts(points) = {
  text(size: 8pt, weight: "bold", [(#points pts)])
}

#let ptseach(points) = {
  text(size: 8pt, weight: "bold", [(#points pts each)])
}

// Answer blank functions
// Use box() to force inline rendering
#let sblank() = box[#h(0.1em)#box(line(length: 1.5em, stroke: 0.5pt))#h(0.1em)]

#let ssblank() = box[#h(0.1em)#box(line(length: 0.5em, stroke: 0.5pt))#h(0.1em)?#h(0.1em)#box(line(length: 0.5em, stroke: 0.5pt))#h(0.1em)]

#let lblank() = box[#h(0.1em)#box(line(length: 10em, stroke: 0.5pt))#h(0.1em)]

#let blank() = ssblank()

// Vertical fill - useful for spacing
#let vf() = v(1fr)

// State variable to track the default question width mode
#let exam-question-display-state = state("exam-question-display", "wide")

// State variable to track the question column width (in narrow mode)
#let exam-question-width-state = state("exam-question-width", 2.37in)

// State variable to track when we're in a force-wide context (like instructions)
#let force-wide-state = state("force-wide", false)

// State variable to track nesting depth of lists (to avoid distribution spacing in nested lists)
#let list-nesting-depth = state("list-nesting-depth", 0)

// Layout modes for answer space
// These functions now work by adjusting the width of content blocks
// The default width is controlled by the exam-question-display-state

// Wide mode: content spans full page width
#let wide(content) = {
  context {
    let mode = exam-question-display-state.get()
    if mode == "narrow" {
      // In narrow-default mode, "wide" blocks need to override the narrow show rules
      // Use force-wide-state to signal that content should be full width
      force-wide-state.update(true)
      content
      force-wide-state.update(false)
    } else {
      // In wide-default mode, content is already wide (no wrapping needed)
      content
    }
  }
}

// Narrow mode: content constrained to left column, right column blank for handwritten answers
// Default left column width is 2.37in (matching LaTeX template)
#let narrow(columnwidth: 2.37in, content) = {
  context {
    let mode = exam-question-display-state.get()
    if mode == "narrow" {
      // In narrow-default mode, this is a no-op (already narrow by default)
      content
    } else {
      // In wide-default mode (traditional), "narrow" blocks constrain to left column
      show par: it => block(width: columnwidth, it)
      show heading: it => block(width: columnwidth, it)
      show enum: it => block(width: columnwidth, it)
      show list: it => block(width: columnwidth, it)
      content
    }
  }
}
// Exam header generator
// Usage: #exam-header(title: "My Exam", subtitle: "Spring", ...)

#let exam-header(
  title: none,
  subtitle: none,
  titlesize: "",
  subtitlesize: "",
  noname: false,
  noinstructions: false,
  instructions: none,
) = {
  v(0.05in)

  // pull fontsize from Quarto if available
  $if(fontsize)$
  let fontsize=$fontsize$
  $else$
  let fontsize=11pt
  $endif$

  // Title; size defaults to fontsize + 3pt unless explicitly specified.
  titlesize = if titlesize != none {titlesize} else {fontsize+3pt}
  if title != none [
    #text(size: titlesize, weight: "regular", title)
    #linebreak()
  ]

  // Subtitle; size defaults to fontsize + 1pt unless explicitly specified.
  subtitlesize = if subtitlesize != none {subtitlesize} else {fontsize+1pt}
  if subtitle != none [
    #v(-0.5em)
    #text(size: subtitlesize, weight: "regular", subtitle)
    #linebreak()
  ]

  // Name field
  if not noname {
    let dy-val = if subtitle != none { 1.2em } else if title != none { 0em } else { -0.5em }
    place(
      right + top,
      dy: dy-val,
      [Name: #h(0.2em) #box(line(length: 2.75in, stroke: 0.5pt))]
    )
  }

  v(0.1in)

  // Instructions (always render in full width, regardless of exam-question-display)
  if not noinstructions {
    let instr = if instructions != "" {
      instructions
    } else {
      [Read each question carefully and fully before answering. Answer all questions using complete sentences unless the question specifies otherwise. Explain your thoughts and provide any necessary context; supporting examples, code, formulas, etc. are encouraged. Clearly state any additional assumptions you make in forming your responses; always be as specific as possible.]
    }
    // Use force-wide state to override narrow mode constraints
    force-wide-state.update(true)
    emph(instr)
    force-wide-state.update(false)
  }

  v(0.2in)
}

// Page setup
#set page(
  $if(papersize)$ paper: "$papersize$", $endif$
  $if(paper)$ paper: "$paper$", $endif$
  $if(margin)$
  margin: (
    $if(margin.x)$ x: $margin.x$, $endif$
    $if(margin.y)$ y: $margin.y$, $endif$
    $if(margin.top)$ top: $margin.top$, $endif$
    $if(margin.bottom)$ bottom: $margin.bottom$, $endif$
    $if(margin.left)$ left: $margin.left$, $endif$
    $if(margin.right)$ right: $margin.right$, $endif$
  ),
  $endif$
)
// Exam Template - Document formatting
// This applies document-wide settings

#show: doc => {
  // Set font from YAML frontmatter (if specified)
  $if(mainfont)$
  set text(font: "$mainfont$")
  $endif$

  // Set font size from YAML frontmatter (if specified)
  $if(fontsize)$
  set text(size: $fontsize$)
  $endif$

  // Set "narrow" column width from YAML frontmatter (if specified)
  // or default to 2.37in
  $if(exam-question-width)$
  let exam-question-width-state=$exam-question-width$
  $else$
  let exam-question-width-state=2.37in
  $endif$

  // Remove page numbering
  set page(numbering: none)

  // Paragraph spacing - no first-line indent
  set par(first-line-indent: 0pt, justify: false)

  // Heading setup (no numbering)
  set heading(numbering: none)

  // Apply default width constraint for narrow mode using show rules
  // This allows pagebreaks to work since we're not wrapping in blocks
  show par: it => {
    context {
      let mode = exam-question-display-state.get()
      let force_wide = force-wide-state.get()
      if mode == "narrow" and not force_wide {
        block(width: exam-question-width-state, it)
      } else {
        it
      }
    }
  }

  show heading: it => {
    context {
      let mode = exam-question-display-state.get()
      let force_wide = force-wide-state.get()
      if mode == "narrow" and not force_wide {
        block(width: exam-question-width-state, it)
      } else {
        it
      }
    }
  }

  show enum: it => {
    context {
      let mode = exam-question-display-state.get()
      let force_wide = force-wide-state.get()
      let width_constraint = if mode == "narrow" and not force_wide { exam-question-width-state } else { 100% }

      // Check if we're in a nested list (by checking if any parent content contains us)
      let nesting = list-nesting-depth.get()

      // Increment nesting depth for any enums inside this one
      list-nesting-depth.update(n => n + 1)

      // Only apply flexible spacing to top-level question enums (numbering "1.")
      // Other numbering styles (like "a)", "i.", etc.) are sub-parts and shouldn't get flexible spacing
      let is_question_enum = (it.numbering == "1." or it.numbering == "1)") and nesting == 0

      let result = if is_question_enum {
        // Top-level question enum: add flexible spacing between items
        let items = it.children
        let start_num = if it.start == auto { 1 } else { it.start }
        let num_items = items.len()

        block(width: width_constraint, {
          // Use numbering function to format items properly
          for (idx, item) in items.enumerate() {
            let item_num = start_num + idx
            // Format using the original numbering style
            let formatted_num = numbering(it.numbering, item_num)
            [#formatted_num #item.body]

            // Add flexible spacing after each item
            // For multi-item enums: add after all items including the last
            // For single-item enums: DON'T add after the last (to keep with following content like code blocks)
            if (num_items > 1) or (idx < num_items - 1) {
              v(1em, weak: true)  // Minimum spacing
              v(1fr)              // Flexible spacing to fill page
            }
          }
        })
      } else {
        // Sub-part enum or nested: just apply width constraint, use default spacing
        block(width: width_constraint, it)
      }

      // Decrement nesting depth
      list-nesting-depth.update(n => n - 1)

      result
    }
  }

  show list: it => {
    context {
      let mode = exam-question-display-state.get()
      let force_wide = force-wide-state.get()
      let width_constraint = if mode == "narrow" and not force_wide { exam-question-width-state } else { 100% }

      // Check if we're in a nested context (either in another list or in an enum)
      let nesting = list-nesting-depth.get()

      // Increment nesting depth
      list-nesting-depth.update(n => n + 1)

      // Bulleted lists should NEVER get flexible spacing (they're always sublists)
      // Only numbered enums at the top level should get flexible spacing
      let result = block(width: width_constraint, it)

      // Decrement nesting depth
      list-nesting-depth.update(n => n - 1)

      result
    }
  }

  // Code blocks (raw blocks) should respect narrow/wide mode
  // Override Quarto's default styling (which sets width: 100%, fill: luma(230))
  show raw.where(block: true): it => {
    set block(
      fill: luma(245),
      inset: 8pt,
      radius: 2pt
    )
    context {
      let mode = exam-question-display-state.get()
      let force_wide = force-wide-state.get()
      if mode == "narrow" and not force_wide {
        // In narrow mode, constrain the block width
        set block(width: exam-question-width-state)
        it
      } else {
        // In wide mode, use full width
        set block(width: 100%)
        it
      }
    }
  }

  doc
}

$body$
