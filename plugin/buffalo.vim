" Vim global plugin file
" Description:	Automatically open buffer when shortest partial tab expands to
"             	unique name.
" Maintainers:	Barry Arthur
"		Israel Chauca <israelchauca@gmail.com>
" Version:	0.1
" Last Change:	2012-03-16
" License:	Vim License (see :help license)
" Location:	plugin/buffalo.vim

" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

if exists("g:loaded_buffalo")
      \ || v:version < 703
      \ || v:version == 703 && !has('patch338')
      \ || &compatible
  let &cpo = s:save_cpo
  finish
endif
let g:loaded_buffalo = 1
let s:aux_map = exists('g:buffalo_aux_map') ? g:buffalo_aux_map : "\<C-G>"

function! s:buffalo(...)
  let cmdline = getcmdline()
  let cmdre = '\C^b\%[uffer]\>'
  if cmdline !~ cmdre
    call feedkeys(' ', 'n')
    return ''
  endif
  if !a:0
    call g:vimple#bl.update()
    call feedkeys(s:aux_map)
    return ' '
  endif
  let char = getchar()
  if char =~ '^\d\+$'
    let char = nr2char(char)
  endif
  let partial = matchstr(cmdline, '^\a\+\s\+\zs.*')
        \ . (char =~'[[:cntrl:]]' ? '' : char)
  if char2nr(char) == 128
    " Backspace, remove the last char.
    " TODO: Make sure it works on different OSes.
    let partial = matchstr(partial, '^.*\ze.')
  endif
  " fnameescape() doesn't escape '.'
  " second escape of '\\' because enclosed in ""
  let filter = 'fnamemodify(v:val["name"], ":p") =~ "' . escape(escape(fnameescape(partial), '.'), '\\') . '"'
  let bl = g:vimple#bl.filter(filter)
  if len(bl.buffers().to_l()) == 1
        \ && (!exists('g:buffalo_autoaccept') || g:buffalo_autoaccept)
    let cmd = matchstr(cmdline, cmdre . '\s\+')
    let args = matchstr(cmdline, cmdre . '\s\+\zs.*') . char
    let cmdline = "\<C-U>". cmd . escape(args, ' ') . "\<CR>\<CR>"
    call feedkeys(cmdline, 'n')
  elseif exists('g:buffalo_pretty') && g:buffalo_pretty
    " Use print() to display matching buffers.
    let cmdline = empty(bl.buffers().to_l())
          \ ? ''
          \ : "call vimple#bl.filter(".string(filter).").print()\<CR>:"
          \   . cmdline
    call feedkeys("\<C-U>" . cmdline . char, 'n')
    call feedkeys(s:aux_map)
  else
    " Use wild settings to display matching buffers.
    call feedkeys(char, 'n')
    call feedkeys(
          \ (empty(bl.buffers().to_l()) ? '' : "\<C-D>")
          \ . s:aux_map)
  endif
  return ''
endfunction

function! s:buffalo_feed()
  if !exists('vimple#bl')
    call vimple#ls#new()
  endif
  if !exists('g:buffalo_buffer_numbers') || g:buffalo_buffer_numbers == 1
    call feedkeys("redraw\<CR>:call vimple#bl.print()\<CR>:b\<Space>", 'n')
    call feedkeys("\<Space>\<BS>")
    return ':'
  endif
  let map = ":\<C-U>".'call feedkeys("\<Space>\<C-D>")'."\<CR>:b"
  return map
endfunction

cnore <expr> <Plug>BuffaloRecursive <SID>buffalo(1)
nnore <expr> <Plug>BuffaloTrigger   <SID>buffalo_feed()

if !hasmapto('<SID>buffalo()')
  cmap <unique><silent><expr> <Space> <SID>buffalo()
endif

if !hasmapto('<Plug>BuffaloTrigger')
  nmap <unique><silent> <leader>l <Plug>BuffaloTrigger
endif

if !hasmapto('<Plug>BuffaloRecursive')
  if !exists('g:buffalo_aux_map')
    cmap <unique><silent> <C-G> <Plug>BuffaloRecursive
  else
    exec 'cmap <unique><silent> ' . g:buffalo_aux_map . ' <Plug>BuffaloTrigger'
  endif
endif

let &cpo = s:save_cpo
unlet s:save_cpo
