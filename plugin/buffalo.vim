" Vim global plugin file
" Description:	Automatically open buffer when shortest partial tab expands to
"             	unique name.
" Maintainers:	Barry Arthur
"		Israel Chauca <israelchauca@gmail.com>
" Version:	0.1
" Last Change:	2012-04-17
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
  let show_partial_matches = 0
  if cmdline !~ cmdre
    " The command is not :buffer.
    " Note: the " \<bs>" mess is an attempt to overcome a problem with
    " cabbrs not expanding.
    call feedkeys(" \<bs>", 'n')
    return ' '
  endif
  if !a:0
    " Just a space.
    call g:vimple#bl.update()
    call feedkeys(s:aux_map)
    return ' '
  endif
  let char = getchar()
  if char =~ '^\d\+$'
    let char = nr2char(char)
  endif
  if char =~ '\e'
    " Cancel action with Esc.
    call feedkeys("\<C-U>\<Esc>", 't')
    return ''
  endif
  if char =~ '\t'
    " Allow <tab> to show partial matches (calling ctrl-d)
    let show_partial_matches = 1
    let char = ''
  endif
  let partial = matchstr(cmdline, '^\a\+\s\+\zs.*')
        \ . (char =~'[[:cntrl:]]' ? '' : char)
  if char2nr(char) == char2nr("\<BS>")
    " Backspace, remove the last char.
    let partial = matchstr(partial, '^.*\ze.')
  endif
  if partial =~ '^\d\+$'
    " Filter by buffer number when the partial is numeric.
    let filter = 'v:val["number"] =~ "'.partial.'"'
  else
    " fnameescape() doesn't escape '.'
    " second escape of '\\' because enclosed in ""
    let filter = 'fnamemodify(v:val["name"], ":p") =~? "'
          \ . escape(escape(fnameescape(partial), '.'), '\\') . '"'
  endif
  let bl = g:vimple#bl.filter(filter)
  if len(bl.buffers().to_l()) == 1
        \ && (!exists('g:buffalo_autoaccept') || g:buffalo_autoaccept)
    " Automagically accept the only match.
    " switch on buffer number to allow for case-insensitive buffer switching
    let cmdline = "\<C-U>:b ". bl.buffers().to_l()[0]["number"] . "\<CR>\<CR>"
    call feedkeys(cmdline, 'n')
    if (!exists('g:buffalo_autoaccept') || ! g:buffalo_autoaccept)
      call feedkeys("\<Esc>:BuffaloConfirm\<CR>", 'n')
    endif
  elseif exists('g:buffalo_pretty') && g:buffalo_pretty
    " Use print() to display matching buffers.
    let cmdline = (empty(bl.buffers().to_l())
          \   ? ''
          \   : "call vimple#bl.filter(".string(filter).").print()\<CR>:")
          \ . cmdline
    call feedkeys("\<C-U>" . cmdline . char, 'n')
    call feedkeys(s:aux_map)
  else
    " Use wild settings to display matching buffers.
    call feedkeys(char, 'n')
    if show_partial_matches
      call feedkeys((len(bl.buffers().to_l()) == 0 ? '' : "\<C-D>"))
    endif
    call feedkeys(s:aux_map)
    return ""
  endif
  return ''
endfunction

function! s:buffalo_feed()
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
command! BuffaloConfirm let s:reply = '' | while s:reply != nr2char(13) | echon "\r" | echon 'Press "Enter" to continue.' | let s:reply = nr2char(getchar()) | endwhile | unlet! s:reply

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
    exec 'cmap <unique><silent> ' . g:buffalo_aux_map
          \ . ' <Plug>BuffaloRecursive'
  endif
endif

let &cpo = s:save_cpo
unlet s:save_cpo
