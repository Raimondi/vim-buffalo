" Automatically open buffer when shortest partial tab expands to unique name
" Barry Arthur, Mar 10 2012

function! Buffalo(...)
  "echom 1
  let cmdline = getcmdline()
  if cmdline !~ '\C^b\%[uffer]\>'
    "echom 2
    return ' '
  endif
  if !a:0
    call g:bl.update()
    call feedkeys("\<C-G>")
    "echom 3
    return ' '
  endif
  let char = getchar()
  if char =~ '^\d\+$'
    let char = nr2char(char)
  endif
  if char =~ '^\s*$'
    call feedkeys(' ', 'n')
    call feedkeys("\<C-D>\<C-G>")
    return ''
  endif
  let partial = matchstr(cmdline, '^\a\+\s\+\zs.*') . char
  " fnameescape() doesn't escape '.'
  " second escape of '\\' because enclosed in ""
  let filter = 'fnamemodify(v:val["name"], ":p") =~ "' . escape(escape(fnameescape(partial), '.'), '\\') . '"'
  "echom 'Filter: '.filter
  let bl = g:bl.filter(filter)
  "echom bl.to_s()
  if len(bl.buffers) == 1
    "echom 5
    return char . "\<CR>\<CR>"
  else
    "echom 6
    call feedkeys(char . "\<C-D>\<C-G>")
    return ""
  endif
endfunction

cnore <expr> <C-G> Buffalo(1)
cnoremap <expr> <Space> Buffalo()
nnoremap <Leader>l :<c-u>call feedkeys("\<space>\<c-d>")<cr>:b
