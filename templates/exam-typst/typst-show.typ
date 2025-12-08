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
      if mode == "narrow" {
        block(width: 2.37in, it)
      } else {
        it
      }
    }
  }

  show heading: it => {
    context {
      let mode = exam-question-width-state.get()
      if mode == "narrow" {
        block(width: 2.37in, it)
      } else {
        it
      }
    }
  }

  show enum: it => {
    context {
      let mode = exam-question-width-state.get()
      if mode == "narrow" {
        block(width: 2.37in, it)
      } else {
        it
      }
    }
  }

  show list: it => {
    context {
      let mode = exam-question-width-state.get()
      if mode == "narrow" {
        block(width: 2.37in, it)
      } else {
        it
      }
    }
  }

  doc
}
