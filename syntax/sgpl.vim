" Vim syntax file
" Language: SGPL (Simple Graphics Programming Language)

if exists("b:current_syntax")
  finish
endif

" Comments
syn match sgplComment "#.*$"

" Strings
syn region sgplString start=/"/ skip=/\\"/ end=/"/

" Numbers (including scientific notation)
syn match sgplNumber "\v[-+]?\d*\.?\d+([eE][-+]?\d+)?"

" Keywords
syn keyword sgplKeyword if for while import struct return

" Built-in functions
syn keyword sgplBuiltin draw print

" Shape keywords
syn keyword sgplShape ellipse circle rectangle square canvas triangle arrow text

" Shape parameters
syn keyword sgplParam major_axis minor_axis thickness x_center y_center contained
syn keyword sgplParam radius height length side_length contained
syn keyword sgplParam x1 y1 x2 y2 x3 y3 base contained
syn keyword sgplParam x_start y_start x_end y_end head_size head_type tail_type curvature contained
syn keyword sgplParam head tail avoid_above avoid_below contained
syn keyword sgplParam literal font font_size contained
syn keyword sgplParam width name contained
syn keyword sgplParam fill_r fill_g fill_b contained

" Color parameters
syn keyword sgplColorParam r g b contained

" Match params inside shape calls
syn region sgplShapeCall start="\v(ellipse|circle|rectangle|square|canvas|triangle|arrow|text)\s*\(" end=")" transparent contains=sgplParam,sgplColorParam,sgplString,sgplNumber,sgplComment,sgplOperator,sgplAssign

" Operators
syn match sgplOperator "\v\*\*"
syn match sgplOperator "\v[-+*/]"
syn match sgplOperator "\v[<>]\=?"
syn match sgplOperator "\v[!=]\="
syn match sgplOperator "\v-\>"

" Delimiters
syn match sgplDelimiter "[(){};,]"

" Assignment
syn match sgplAssign "\v\="

" Highlight links
hi def link sgplComment Comment
hi def link sgplString String
hi def link sgplNumber Number
hi def link sgplKeyword Keyword
hi def link sgplBuiltin Function
hi def link sgplShape Type
hi def link sgplParam Identifier
hi def link sgplColorParam Special
hi def link sgplOperator Operator
hi def link sgplDelimiter Delimiter
hi def link sgplAssign Operator

let b:current_syntax = "sgpl"
