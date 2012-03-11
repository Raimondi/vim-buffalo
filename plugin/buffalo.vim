" Automatically open buffer when shortest partial tab expands to unique name
" Barry Arthur, Mar 10 2012

function! Buffalo(...)
  "echom 1
  let cmdline = getcmdline()
  let cmdre = '\C^b\%[uffer]\>'
  if cmdline !~ cmdre
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
  let partial = matchstr(cmdline, '^\a\+\s\+\zs.*') . char
  " fnameescape() doesn't escape '.'
  " second escape of '\\' because enclosed in ""
  let filter = 'fnamemodify(v:val["name"], ":p") =~ "' . escape(escape(fnameescape(partial), '.'), '\\') . '"'
  "echom 'Filter: '.filter
  let bl = g:bl.filter(filter)
  "echom bl.to_s()
  if len(bl.buffers().to_l()) == 1
    "echom 5
    let cmd = matchstr(cmdline, cmdre . '\s\+')
    let args = matchstr(cmdline, cmdre . '\s\+\zs.*') . char
    let cmdline = "\<C-U>". cmd . escape(args, ' ')
    call feedkeys(cmdline . "\<CR>\<CR>", 'n')
    return ''
  else
    "echom 6
    call feedkeys(char, 'n')
    call feedkeys("\<C-D>\<C-G>")
    return ""
  endif
endfunction

cnore <expr> <C-G> Buffalo(1)
cnoremap <expr> <Space> Buffalo()
nnoremap <Leader>l :<c-u>call feedkeys("\<space>\<c-d>")<cr>:b
