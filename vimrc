if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
   set fileencodings=ucs-bom,utf-8,latin1
endif

set nocompatible	" Use Vim defaults (much better!)
set bs=indent,eol,start		" allow backspacing over everything in insert mode
"set ai			" always set autoindenting on
"set backup		" keep a backup file
set viminfo='20,\"10000	" read/write a .viminfo file, don't store more
			" than 50 lines of registers
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set expandtab
set tabstop=2 
set shiftwidth=2
set softtabstop=2
set laststatus=2

execute pathogen#infect()

"folding settings
""za = toggle fold on this scope
"zM = fold all
""zR = unfold all
"#zo = unfold # scopes down
""#zc = fold # scopes up

set foldmethod=syntax   "fold based on syntax. Alt method: "indent"
set foldnestmax=20      "deepest fold is 20 levels
set nofoldenable        "dont fold by default
set foldlevel=1         "this is just what i use
highlight Folded ctermbg=black ctermfg=darkgrey

" Only do this part when compiled with support for autocommands
if has("autocmd")
  augroup fedora
  autocmd!
  " In text files, always limit the width of text to 78 characters
  " autocmd BufRead *.txt set tw=78
  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
  \   exe "normal! g'\"" |
  \ endif
  " don't write swapfile on most commonly used directories for NFS mounts or USB sticks
  autocmd BufNewFile,BufReadPre /media/*,/mnt/* set directory=~/tmp,/var/tmp,/tmp
  " start with spec file template
  autocmd BufNewFile *.spec 0r /usr/share/vim/vimfiles/template.spec
  augroup END
endif

if has("cscope") && filereadable("/usr/bin/cscope")
   set csprg=/usr/bin/cscope
   set csto=0
   set cst
   set nocsverb
   " add any database in current directory
   if filereadable("cscope.out")
      cs add cscope.out
   " else add database pointed to by environment
   elseif $CSCOPE_DB != ""
      cs add $CSCOPE_DB
   endif
   set csverb
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

filetype plugin on

if &term=="xterm"
     set t_Co=8
     set t_Sb=[4%dm
     set t_Sf=[3%dm
endif

set t_Co=256

" Don't wake up system with blinking cursor:
" http://www.linuxpowertop.org/known.php
let &guicursor = &guicursor . ",a:blinkon0"

set number

" Open as zip files
au BufReadCmd *.jar,*.whl,*.docx,*.xlsx call zip#Browse(expand("<amatch>"))

" Filetype syntax highlighting
au BufNewFile,BufRead *.toml set filetype=cfg
au BufNewFile,BufRead Pipfile set filetype=cfg
au BufNewFile,BufRead *.ctpl set filetype=c

" Trailing Whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" Extra Syntax highlighting options
let g:jsx_ext_required = 0 " Allow JSX in normal JS files
let g:syntastic_javascript_checkers = ['eslint']

" NERDCommenter
inoremap <F2> <C-o>:call NERDComment(0,'sexy')<cr>
inoremap <F3> <C-o>:call NERDComment(0,'toggle')<cr>
inoremap <F4> <C-o>:call NERDComment(0,'uncomment')<cr>
noremap <F2> :call NERDComment(0,'sexy')<cr>
noremap <F3> :call NERDComment(0,'toggle')<cr>
noremap <F4> :call NERDComment(0,'uncomment')<cr>

" Undotree config
if has("persistent_undo")
    set undodir='~/.undodir/'
    set undofile
endif
nnoremap <F5> :UndotreeToggle<cr>

" Signify
highlight DiffAdd           cterm=bold ctermbg=0 ctermfg=119
highlight DiffDelete        cterm=bold ctermbg=0 ctermfg=167
highlight DiffChange        cterm=bold ctermbg=0 ctermfg=227
highlight SignifySignAdd    cterm=bold ctermbg=0 ctermfg=119
highlight SignifySignDelete cterm=bold ctermbg=0 ctermfg=167
highlight SignifySignChange cterm=bold ctermbg=0 ctermfg=227
highlight SignColumn        ctermbg=0
let g:signify_line_highlight = 0

" Fugitive config
nnoremap <F6> :Gblame<cr>

" Ctrl-SF
nnoremap <C-F> :CtrlSF 

" Airline
set noshowmode
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

" Multicursor
:vmap m :MultipleCursorsFind ^.<cr>ii

" JsBeautify
nmap <C-J> :call JsBeautify()<cr>

" unicode symbols
"let g:airline_left_sep = '»'
"let g:airline_left_sep = '▶'
"let g:airline_right_sep = '«'
"let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
"let g:airline_symbols.branch = '⎇'
"let g:airline_symbols.paste = 'ρ'
"let g:airline_symbols.paste = 'Þ'
"let g:airline_symbols.paste = '∥'
"let g:airline_symbols.whitespace = 'Ξ'

let g:airline_theme = 'papercolor'

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
"let g:syntastic_typescript_tsc_fname = ''
" For Gradle-based Projects, use:
" https://github.com/Scuilion/gradle-syntastic-plugin
"let g:syntastic_java_checkers=['javac']
"let g:syntastic_java_javac_config_file_enabled = 1

" Indent Guides
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_auto_colors = 0
hi IndentGuidesOdd  ctermbg=black
hi IndentGuidesEven ctermbg=1000
hi Normal           none

" Rainbow Parentheses
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces
let g:rbpt_colorpairs = [
    \ ['brown',       'RoyalBlue3'],
    \ ['Darkblue',    'SeaGreen3'],
    \ ['darkgray',    'DarkOrchid3'],
    \ ['darkgreen',   'firebrick3'],
    \ ['darkcyan',    'RoyalBlue3'],
    \ ['darkred',     'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['brown',       'firebrick3'],
    \ ['gray',        'RoyalBlue3'],
    \ ['red',         'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['Darkblue',    'firebrick3'],
    \ ['darkgreen',   'RoyalBlue3'],
    \ ['darkcyan',    'SeaGreen3'],
    \ ['darkred',     'DarkOrchid3'],
    \ ['red',         'firebrick3'],
    \ ]

" Command-T: <Leader>T (which is usually: '\')

" Most Recent Session
:nmap <C-S> :mksession ~/.mysession.vim<cr>
:nmap <C-O> :source ~/.mysession.vim<cr>

:" map Mac OS X Terminal.app default Home and End
:map <C-A> <Home>
:map <C-E> <End>
:map <ESC>[H <Home>
:map <ESC>[F <End>
:map! <C-A> <Home>
:map! <C-E> <End>
:map! <ESC>[H <Home>
:map! <ESC>[F <End>
