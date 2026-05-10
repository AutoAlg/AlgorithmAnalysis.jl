\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{graph}

\LoadClass[tikz]{standalone}

\RequirePackage{amsmath,amssymb}

\usetikzlibrary{automata,calc,positioning,arrows,arrows.meta,patterns,decorations.pathmorphing,decorations.markings,shapes.geometric,bending}

\xdefinecolor{myltgrey}{rgb}{0.6941,0.7804,0.9098}% (half grey)

\tikzset{every picture/.style={
    ->,
    >=Stealth,
    node distance=2cm,
    thick,
    every edge/.style={draw=black},
    auto
  }
}

\tikzset{signal/.style={%
  ->,
  semithick,
  >=latex,
  rounded corners,
  }
}

\tikzset{small/.style={inner sep=2.5mm}}
\tikzset{medium/.style={inner sep=4mm}}
\tikzset{large/.style={inner sep=5.5mm}}

\tikzset{block/.style={%
  anchor=center,
  rounded corners,
  semithick,
  draw,
  fill=blue!10,
  medium
  }
}

\tikzset{square/.style={%
  regular polygon,
  regular polygon sides=4,
  minimum size=1.2cm,
  outer sep=0pt,
  inner sep=0pt,
  }
}

\tikzset{block diagram/.style={%
  every path/.style={%
    ->,
    >=latex,
    rounded corners,
    }
  }
}