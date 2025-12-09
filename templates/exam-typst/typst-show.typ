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
      let mode = exam-question-width-state.get()
      let force_wide = force-wide-state.get()
      if mode == "narrow" and not force_wide {
        block(width: 2.37in, it)
      } else {
        it
      }
    }
  }

  show heading: it => {
    context {
      let mode = exam-question-width-state.get()
      let force_wide = force-wide-state.get()
      if mode == "narrow" and not force_wide {
        block(width: 2.37in, it)
      } else {
        it
      }
    }
  }

  show enum: it => {
    context {
      let mode = exam-question-width-state.get()
      let force_wide = force-wide-state.get()
      let width_constraint = if mode == "narrow" and not force_wide { 2.37in } else { 100% }

      // Get the items and their content
      let items = it.children

      // Create a grid with flexible spacing between items to fill the page
      block(width: width_constraint,
        grid(
          rows: items.map(_ => auto),
          row-gutter: 1fr,
          ..items.enumerate().map(((idx, item)) => {
            // Manually format numbered list items to avoid recursion
            [#(idx + 1). #item.body]
          })
        )
      )
    }
  }

  show list: it => {
    context {
      let mode = exam-question-width-state.get()
      let force_wide = force-wide-state.get()
      let width_constraint = if mode == "narrow" and not force_wide { 2.37in } else { 100% }

      // Get the items and their content
      let items = it.children

      // Create a grid with flexible spacing between items to fill the page
      block(width: width_constraint,
        grid(
          rows: items.map(_ => auto),
          row-gutter: 1fr,
          ..items.map(item => {
            // Manually format bulleted list items to avoid recursion
            [• #item.body]
          })
        )
      )
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
      let mode = exam-question-width-state.get()
      let force_wide = force-wide-state.get()
      if mode == "narrow" and not force_wide {
        // In narrow mode, constrain the block width
        set block(width: 2.37in)
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
