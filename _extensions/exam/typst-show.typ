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
      let mode = exam-question-layout-state.get()
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
      let mode = exam-question-layout-state.get()
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
      let mode = exam-question-layout-state.get()
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
      let mode = exam-question-layout-state.get()
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
      let mode = exam-question-layout-state.get()
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
