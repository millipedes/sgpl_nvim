" Vim indent file for SGPL

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetSgplIndent()
setlocal indentkeys=0{,0},!^F,o,O

function! GetSgplIndent()
  let lnum = prevnonblank(v:lnum - 1)
  if lnum == 0
    return 0
  endif

  let ind = indent(lnum)
  let line = getline(lnum)
  let cline = getline(v:lnum)

  " Increase indent after {
  if line =~ '{[^}]*$'
    let ind += shiftwidth()
  endif

  " Decrease indent for }
  if cline =~ '^\s*}'
    let ind -= shiftwidth()
  endif

  return ind
endfunction
