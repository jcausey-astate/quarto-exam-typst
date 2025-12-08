// Exam Template - Document formatting
// This applies document-wide settings

#show: doc => {
  // Remove page numbering
  set page(numbering: none)

  // Paragraph spacing - no first-line indent
  set par(first-line-indent: 0pt, justify: false)

  // Heading setup (no numbering)
  set heading(numbering: none)

  doc
}
