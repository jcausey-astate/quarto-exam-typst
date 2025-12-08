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
#let sblank() = {
  h(0.1em)
  line(length: 1.5em, stroke: 0.5pt)
  h(0.1em)
}

#let ssblank() = {
  h(0.1em)
  line(length: 0.5em, stroke: 0.5pt)
  h(0.1em)
  [?]
  h(0.1em)
  line(length: 0.5em, stroke: 0.5pt)
  h(0.1em)
}

#let lblank() = {
  h(0.1em)
  line(length: 10em, stroke: 0.5pt)
  h(0.1em)
}

#let blank() = ssblank()

// Vertical fill - useful for spacing
#let vf() = v(1fr)

// Wide and narrow environments
#let wide(content) = {
  block(width: 100%, content)
}

#let narrow(answerwidth: 2.37in, content) = {
  block(width: 100% - answerwidth, content)
}
