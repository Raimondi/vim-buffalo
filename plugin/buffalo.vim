" Vim global plugin file
" Description:	Automatically open buffer when shortest partial tab expands to
"             	unique name.
" Maintainers:	Barry Arthur
"		Israel Chauca <israelchauca@gmail.com>
" Version:	0.1
" Last Change:	2012-03-16
" License:	Vim License (see :help license)
" Location:	plugin/buffalo.vim

if exists("g:loaded_buffalo")
      \ || v:version < 703
      \ || v:version == 703 && !has('patch338')
      \ || &compatible
  finish
endif
let g:loaded_buffalo = 1

" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

function! s:buffalo(...)
  let cmdline = getcmdline()
  let cmdre = '\C^b\%[uffer]\>'
  if cmdline !~ cmdre
    return ' '
  endif
  if !a:0
    call g:bl.update()
    call feedkeys("\<C-G>")
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
  let bl = g:bl.filter(filter)
  if len(bl.buffers().to_l()) == 1
    let cmd = matchstr(cmdline, cmdre . '\s\+')
    let args = matchstr(cmdline, cmdre . '\s\+\zs.*') . char
    let cmdline = "\<C-U>". cmd . escape(args, ' ')
    call feedkeys(cmdline . "\<CR>\<CR>", 'n')
    return ''
  else
    call feedkeys(char, 'n')
    call feedkeys("\<C-D>\<C-G>")
    return ""
  endif
endfunction

function! s:buffalo_feed()
  echom 1
  if !exists('g:buffalo_aux_map')
    let trigger = "\<c-d>"
  else
    let trigger = g:buffalo_aux_map
  endif
  let map = ":\<C-U>".'call feedkeys("\<Space>'.trigger.'")'."\<CR>:b"
  return map
endfunction

cnore <expr> <Plug>BuffaloSpace     <SID>buffalo()
cnore <expr> <Plug>BuffaloRecursive <SID>buffalo(1)
nnore <expr> <Plug>BuffaloTrigger   <SID>buffalo_feed()

if !hasmapto('<Plug>BuffaloSpace')
  silent! cmap <unique><silent> <Space> <Plug>BuffaloSpace
endif

if !hasmapto('<Plug>BuffaloTrigger')
  silent! nmap <unique><silent> <leader>l <Plug>BuffaloTrigger
endif

if !hasmapto('<Plug>BuffaloRecursive')
  if !exists('g:buffalo_aux_map')
    silent! cmap <unique><silent> <C-G> <Plug>BuffaloRecursive
  else
    exec 'silent! cmap <unique><silent> ' . g:buffalo_aux_map . ' <Plug>BuffaloTrigger'
  endif
endif

let &cpo = s:save_cpo
unlet s:save_cpo
