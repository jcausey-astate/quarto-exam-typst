// Quarto Typst Exam Template
// Converted from LaTeX exam template

#let exam(
  title: none,
  subtitle: none,
  titlesize: 18pt,
  subtitlesize: 14pt,
  noname: false,
  noinstructions: false,
  instructions: none,
  margin: 2cm,
  colwidth: 2.37in,
  fontsize: 10pt,
  mainfont: "Times New Roman",
  body
) = {
  // Page setup
  let bottom-margin = margin + (margin / 2)
  set page(
    paper: "us-letter",
    margin: (top: margin, bottom: bottom-margin, left: margin, right: margin),
    numbering: none,
  )

  // Font configuration
  set text(font: mainfont, size: fontsize)

  // Paragraph spacing
  set par(spacing: 0.65em, leading: 0.65em, justify: false)

  // List formatting
  set enum(
    indent: 0em,
    body-indent: 0.65em,
    spacing: auto,
    numbering: "1.",
  )

  set list(
    indent: 1.5em,
    body-indent: 0.5em,
  )

  // Heading setup (no numbering)
  set heading(numbering: none)

  // Header section
  v(0.05in)

  // Title
  if title != none {
    text(size: titlesize, weight: "regular", title)
    linebreak()
  }

  // Subtitle
  if subtitle != none {
    v(-0.5em)
    text(size: subtitlesize, weight: "regular", subtitle)
    linebreak()
  }

  // Name field
  if not noname {
    place(
      right + top,
      dy: if subtitle != none { 1.2em } else if title != none { 0em } else { -0.5em },
      [Name: #h(0.2em) #box(line(length: 2.75in, stroke: 0.5pt))]
    )
  }

  v(0.1in)

  // Instructions
  if not noinstructions {
    let instr = if instructions != none {
      instructions
    } else {
      [Read each question carefully and fully before answering. Answer all questions using complete sentences unless the question specifies otherwise. Explain your thoughts and provide any necessary context; supporting examples, code, formulas, etc. are encouraged. Clearly state any additional assumptions you make in forming your responses; always be as specific as possible.]
    }
    emph(instr)
  }

  v(0.2in)

  // Body content
  body

  v(0.5in)
}

// Helper function for point values
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
// Note: In Typst, we use block containers instead of margin adjustments
// These create full-width or constrained-width blocks
#let wide(content) = {
  block(width: 100%, content)
}

#let narrow(answerwidth: 2.37in, content) = {
  block(width: 100% - answerwidth, content)
}
