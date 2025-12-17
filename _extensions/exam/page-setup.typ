
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
