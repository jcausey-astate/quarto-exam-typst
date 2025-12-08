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
#let exam-question-width-state = state("exam-question-width", "wide")

// State variable to track when we're in a force-wide context (like instructions)
#let force-wide-state = state("force-wide", false)

// Layout modes for answer space
// These functions now work by adjusting the width of content blocks
// The default width is controlled by the exam-question-width-state

// Wide mode: content spans full page width
#let wide(content) = {
  context {
    let mode = exam-question-width-state.get()
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
    let mode = exam-question-width-state.get()
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
