// Exam header generator
// Usage: #exam-header(title: "My Exam", subtitle: "Spring 2025", ...)

// Import the force-wide-state from typst-template.typ
// Import removed - available via template-partials concatenation
// #import "typst-template.typ": force-wide-state

#let exam-header(
  title: none,
  subtitle: none,
  titlesize: 20pt,
  subtitlesize: 14pt,
  noname: false,
  noinstructions: false,
  instructions: none,
) = {
  v(0.05in)

  // Title
  if title != none [
    #text(size: titlesize, weight: "regular", title)
    #linebreak()
  ]

  // Subtitle
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
    let instr = if instructions != none {
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
