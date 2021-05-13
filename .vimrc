let mapleader="\<space>"
let g:email ='garrettrmooney@gmail.com'

" ================
" vim-plug
" https://github.com/junegunn/vim-plug
" ================
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
        endif

call plug#begin('~/.vim/plugged')
Plug 'elmcast/elm-vim'
" Plug 'integralist/vim-mypy'
" Plug 'lervag/vimtex'
" Plug 'psf/black'
" Plug 'sjl/gundo.vim'
Plug '/home/garrett/.fzf/bin/fzf'
Plug 'danro/rename.vim'
Plug 'deoplete-plugins/deoplete-jedi'
Plug 'eigenfoo/stan-vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'gaalcaras/ncm-R'
Plug 'godlygeek/tabular'
Plug 'JuliaEditorSupport/julia-vim'
Plug 'jalvesaq/Nvim-R', {'branch': 'stable'}
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'junegunn/seoul256.vim'
Plug 'lilydjwg/colorizer'
" Plug 'maverickg/stan.vim'
Plug 'ncm2/ncm2'
Plug 'pangloss/vim-javascript'
Plug 'preservim/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'sirver/UltiSnips'
Plug 'szymonmaszke/vimpyter'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'w0rp/ale'
Plug 'wellle/context.vim'
" For vim-snipmate
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
" end vim-snipmate
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
  Plug 'JuliaEditorSupport/deoplete-julia'
endif
let g:deoplete#enable_at_startup = 1
call plug#end()

" ================
" rtichoke
" ================
let R_app = "radian"
let R_cmd = "R"
let R_hl_term = 0
let R_args = []  " if you had set any
let R_bracketed_paste = 1

" ================
" nvim-completion-manager / vim-hug-neovim-rpc
" ================
" let g:python3_host_prog = '/usr/bin/python3.6'

" ================
" ALE (linter)
" ================
let g:ale_emit_conflict_warnings = 0

" ================
" Pathogen
" ================
set nocp
execute pathogen#infect()
syntax on
filetype plugin indent on

" ================
" NERDTree
" ================
map <F2> :NERDTreeToggle<CR>

" ================
" Tagbar
" ================
" nmap <F8> :TagbarToggle<CR>
" Ctrl-W to switch window panes
" Caps-W ....
" sometimes has to be pressed twice

" ================
" Powerline
" ================
set rtp+=/usr/share/powerline/bindings/vim/
" python from powerline.vim import setup as powerline_setup
" python powerline_setup()
" python del powerline_setup

set laststatus=2
" let g:Powerline_symbols = 'fancy'
" set nocompatible    " Disable vi-compatibility
" set laststatus=2    " Always show the statusline
" set encoding=utf-8  " Necessary to show Unicode glyphs
set t_Co=256        " support 256 colors
" " not sure if below line goes here or some other directory where cache is
" let g:Powerline_cache_dir = simplify(expand('<sfile>:p:h') .'/..')

" ================
" Airline
" ================
" let g:airline_powerline_fonts=1

" ================
" PEP 8
" ================
"#     autocmd FileType python set nowrap
"set textwidth=79	" lines longer than 79 columns will be broken
autocmd Filetype python set autoindent		         " align the new line indent with the previous line
autocmd Filetype python set expandtab		         " insert spaces when hitting TABs
autocmd Filetype python set shiftround		         " round indent to multiple of 'shiftwidth'
autocmd Filetype python set shiftwidth=4	         " operation >> indents 4 columns; << unindents 4 columns
autocmd Filetype python set softtabstop=4	         " insert/delete 4 spaces when hitting a TAB/BACKSPACE
autocmd Filetype python set tabstop=4		         " a hard TAB displays as 4 columns
" TESTING: trying these out from
" https://stackoverflow.com/questions/65076/how-do-i-set-up-vim-autoindentation-properly-for-editing-python-files
autocmd Filetype python set textwidth=120	         " break lines when line length increases
autocmd Filetype python set backspace=indent,eol,start   " powerful backspace
autocmd Filetype python set ruler                        " show line and column number
autocmd Filetype python syntax on                        " syntax highlighting
autocmd Filetype python set showcmd                      " show (partial) command in status line

" ================
" 2015-07-26
" tmux/vim/zsh
" ================

" give us 256 color schemes!
set term=screen-256color

" give us nice EOL (end of line) characters
" set list
" set listchars=tab:▸\ ,eol:¬

" ================
" 2015-07-26
" Vundle
" ================
" mandatory defaults
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" our plugins
Plugin 'benmills/vimux'
Plugin 'bling/vim-airline'
Plugin 'derekwyatt/vim-scala'
Plugin 'easymotion/vim-easymotion'
Plugin 'flazz/vim-colorschemes' " nice colors!
Plugin 'gmarik/Vundle.vim'      " vundle
" Plugin 'Vimjas/vim-python-pep8-indent'

" colorscheme
colo seoul256

" 2015-07-27
" Dr Bunsen
syntax enable
" let g:solarized_termtrans = 1
" let g:solarized_termcolors=256
" colorscheme solarized
" togglebg#map("<F5>")

" Yank text to clipboard (works on OSX?)
noremap <leader>y "*y
noremap <leader>yy "*Y

" Preserve indentation while pasting text from the OSX clipboard
noremap <leader>p :set paste<CR>:put *<CR>:set nopaste<CR>

" http://sheerun.net/2014/03/21/how-to-boost-your-vim-productivity/
" new mappings w <Space> leader

" <space>o to open a new file
nnoremap <Leader>q :q<CR>

" <space>o to open a new file
nnoremap <Leader>o :open<CR>

" <space>w to save
nnoremap <Leader>w :w<CR>

" <space>e to reload file
nnoremap <Leader>e :e<CR>

" Enter visual line mode with <Space><Space>
nmap <Leader><Leader> V

" Don't show insert below airline
set noshowmode

"==============================
"From Windows ~/_vimrc
"==============================
"# set nocompatible              " be iMproved, required
"# filetype off                  " required
"# set tabstop=8
"# set expandtab
"# set softtabstop=4
"# set shiftwidth=4
"# filetype indent on

" paste at end of line w `,`
" nmap , $p

"# " ====================================================
"# " VUNDLE
"# " ====================================================
"# " set the runtime path to include Vundle and initialize
"# set rtp+=~/vimfiles/bundle/Vundle.vim
"# let path='~/vimfiles/bundle'
"# call vundle#begin(path)
"# " alternatively, pass a path where Vundle should install plugins
"# "call vundle#begin('~/some/path/here')
"#
"# " let Vundle manage Vundle, required
"# Plugin 'gmarik/Vundle.vim'
"
"# " The following are examples of different formats supported.
"# " Keep Plugin commands between vundle#begin/end.
"# " plugin on GitHub repo
"# Plugin 'tpope/vim-fugitive'
"# " plugin from http://vim-scripts.org/vim/scripts.html
"# Plugin 'L9'
"# " Git plugin not hosted on GitHub
"# Plugin 'git://git.wincent.com/command-t.git'
"# " git repos on your local machine (i.e. when working on your own plugin)
"# Plugin 'file:///home/gmarik/path/to/plugin'
"# " The sparkup vim script is in a subdirectory of this repo called vim.
"# " Pass the path to set the runtimepath properly.
"# Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
"# " Avoid a name conflict with L9
"# Plugin 'user/L9', {'name': 'newL9'}
"# Plugin 'lervag/vim-latex'
"# Plugin 'tmhedberg/SimpylFold'
"
"# " All of your Plugins must be added before the following line
"# call vundle#end()            " required
"# filetype plugin indent on    " required
"# " To ignore plugin indent changes, instead use:
"# "filetype plugin on
"# "
"# " Brief help
"# " :PluginList       - lists configured plugins
"# " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
"# " :PluginSearch foo - searches for foo; append `!` to refresh local cache
"# " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"# "
"# " see :h vundle for more details or wiki for FAQ
"# " Put your non-Plugin stuff after this lineset nocompatible
"# filetype off
"# set rtp+=~/.vim/bundle/vundle/
"# call vundle#rc()
"# set nocompatible
"# source $VIMRUNTIME/vimrc_example.vim
"# source $VIMRUNTIME/mswin.vim
"# behave mswin
"
"# " ====================================================================
"# "  Settings from: <unlogic.co.uk/2013/02/08/vim-as-a-python-ide/
"# " ====================================================================
"# augroup vimrc_autocmds
"#     autocmd!
""#     " highlight characters past column 120
"#     autocmd FileType python highlight Excess ctermbg=DarkGrey guibg=Black
"#     autocmd FileType python match Excess /\%120v.*/
"#     autocmd FileType python set nowrap
"#     augroup END



"# " ====================================================================
"# " I think Vim-R starts here (b/c of latex mentions), but is not fully configured
"# " ====================================================================
"# " REQUIRED. This makes vim invoke Latex-Suite when you open a tex file.
"# filetype plugin on
"#
"# " IMPORTANT: win32 users will need to have 'shellslash' set so that latex
"# " can be called correctly.
"# set shellslash
"#
"# " IMPORTANT: grep will sometimes skip displaying the file name if you
"# " search in a singe file. This will confuse Latex-Suite. Set your grep
"# " program to always generate a file-name.
"# set grepprg=grep\ -nH\ $*
"#
"# " OPTIONAL: This enables automatic indentation as you type.
"# filetype indent on
"#
"# " OPTIONAL: Starting with Vim 7, the filetype of empty .tex files defaults to
"# " 'plaintex' instead of 'tex', which results in vim-latex not being loaded.
"# " The following changes the default filetype back to 'tex':
"# let g:tex_flavor='latex'
"# set diffexpr=MyDiff()
"# function MyDiff()
"#   let opt = '-a --binary '
"#   if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
"#   if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
"#   let arg1 = v:fname_in
"#   if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
"#   let arg2 = v:fname_new
"#   if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
"#   let arg3 = v:fname_out
"#   if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
"#   let eq = ''
"#   if $VIMRUNTIME =~ ' '
"#     if &sh =~ '\<cmd'
"#       let cmd = '""' . $VIMRUNTIME . '\diff"'
"#       let eq = '"'
"#     else
"#       let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
"#     endif
"#   else
"#     let cmd = $VIMRUNTIME . '\diff'
"#   endif
"#   silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
"endfunction
"
"# " =======================================================
"# " PATHOGEN
"# " =======================================================
"# " Pathogen
"# execute pathogen#infect()
"# syntax on
"# filetype plugin indent on
"#
"# " Automatically open NERDTree when vim starts up
"# " autocmd vimenter * NERDTree
"# " autocmd StdinReadPre * let s:st_in=1
"# " autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
"#
"# " =======================================================
"# " NERDTree
"# " =======================================================
"# " Toggle NERDTree
"# map <C-n> :NERDTreeToggle<CR>
"#
 
" Ctrl-P
set runtimepath^=~/.vim/bundle/ctrlp.vim

" =======================================================
" EASYMOTION
" =======================================================
" Easymotion
let g:EasyMotion_do_mapping = 0 " Disable default Mappings

" Dot repeat
nmap s <Plug>(easymotion-s)
omap t <Plug>(easymotion-bd-tl)
let g:EasyMotion_use_upper = 1
let g:EasyMotion_smartcase = 1
let g:EasyMotion_use_smartsign_us = 1

" Bi-directional find motion
" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
nmap s <Plug>(easymotion-s)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average it may be more comfortable.
" nmap s <Plug>(easymotion-s2)
" nmap t <Plug>(easymotion-t2)

" Turn on case insensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
map <Leader>l <Plug>(easymotion-lineforward)
map <Leader>h <Plug>(easymotion-linebackward)

" n-character search motion
map / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)

" These `n` & `N` mappings are options. You do not have to map `n` & `N` to EasyMotion.
" Without these mappings, `n` & `N` works fine. (These mappings just provide
" different highlight method and have some other features )
map n <Plug>(easymotion-next)
map N <Plug>(easymotion-prev)

"" ================================
"" Syntastic
"" ================================
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*

" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 1
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0

" syntastic r lintr
" let g:syntastic_enable_r_lintr_checker = 1
" let g:syntastic_r_checkers = ['lintr']

" python linter
" let g:syntastic_python_checkers = ['flake8', 'pylint']

"" ================================
"" Color Scheme
"" ================================
"" Solarized color scheme
"syntax enable
"set background=dark
"" colorscheme solarized
"
"" ================================
"" Pydiction
"" ================================
"filetype plugin on
"let g:pydiction_location = '/c/users/dks0505921/vimfiles/bundle/pydiction/complete-dict'
" let g:pydiction_menu_height = 3

"" ================================
"" tmux + vim + r
"" nvim-R
"" ================================
"" https://github.com/vsbuffalo/devnotes/wiki/Vim,-R,-and-Tmux:-Minimal-Configuration
"" ^ 2014 (likely deprecated)
" R script settings
let maplocalleader = ","
vmap <Space> <Plug>RDSendSelection
nmap <Space> <Plug>RDSendLine
let vimrplugin_vsplit=1
"let R_vsplit = 1 " not working --> BIG PAIN IN MY ASS!
let R_assign = 2

"filetype plugin on

"" ================================
"" julia
"" ================================

"" ================================
"" golang
"" ================================
autocmd BufReadPost *.go map <F5> :GoRun<space><c-r>%<Enter>
"autocmd BufReadPost *.go inoremap ;c //<space><Esc>0j
"autocmd BufReadPost *.go inoremap ;f function(<++>)<space>{<space><++><space>}
"autocmd BufReadPost *.go inoremap ;i Infer({method:<space>'<++>',<space>samples:<space><++>},<space><++>)
"autocmd BufReadPost *.go inoremap ;t <++><space>?<space><++><space>:<space><++>
"autocmd BufReadPost *.go inoremap ;v var<space><++><space>=<space>
"autocmd BufReadPost *.go set shiftwidth=2   	" operation >> indents 2 columns; << unindents 2 columns
"autocmd BufReadPost *.go set tabstop=2	" a hard TAB displays as 2 columns
"autocmd BufReadPost *.go set expandtab	" insert spaces when hitting TABs
"autocmd BufReadPost *.go set softtabstop=2	" insert/delete 2 spaces when hitting a TAB/BACKSPACE
"autocmd BufReadPost *.go set shiftround	" round indent to multiple of 'shiftwidth'
"autocmd BufReadPost *.go set autoindent	" align the new line indent with the previous line


"" ================================
"" webppl
"" ================================
" javascript probabilistic programming language
au BufReadPost *.wppl set syntax=javascript
autocmd BufReadPost *.wppl map <F5> :!webppl<space><c-r>%<Enter>
autocmd BufReadPost *.wppl inoremap ;c //<space><Esc>0j
autocmd BufReadPost *.wppl inoremap ;f function(<++>)<space>{<space><++><space>}
autocmd BufReadPost *.wppl inoremap ;i Infer({method:<space>'<++>',<space>samples:<space><++>},<space><++>)
autocmd BufReadPost *.wppl inoremap ;t <++><space>?<space><++><space>:<space><++>
autocmd BufReadPost *.wppl inoremap ;v var<space><++><space>=<space>
autocmd BufReadPost *.wppl set shiftwidth=2   	" operation >> indents 2 columns; << unindents 2 columns
autocmd BufReadPost *.wppl set tabstop=2	" a hard TAB displays as 2 columns
autocmd BufReadPost *.wppl set expandtab	" insert spaces when hitting TABs
autocmd BufReadPost *.wppl set softtabstop=2	" insert/delete 2 spaces when hitting a TAB/BACKSPACE
autocmd BufReadPost *.wppl set shiftround	" round indent to multiple of 'shiftwidth'
autocmd BufReadPost *.wppl set autoindent	" align the new line indent with the previous line

"" ================================
"" latex
"" ================================
" Compile document using xelatex:
autocmd FileType tex inoremap <F5> <Esc>:!xelatex<space><c-r>%<Enter>a
autocmd FileType tex nnoremap <F5> :!xelatex<space><c-r>%<Enter>

"" ================================
"" markdown
"" ================================
" autocmd Filetype markdown,rmd map <leader>w yiWi[<esc>Ea](<esc>pa)
autocmd Filetype markdown,rmd inoremap ;n ---<Enter><Enter>
autocmd Filetype markdown,rmd inoremap ;b ****<++><Esc>F*hi
autocmd Filetype markdown,rmd inoremap ;s ~~~~<++><Esc>F~hi
autocmd Filetype markdown,rmd inoremap ;e **<++><Esc>F*i
autocmd Filetype markdown,rmd inoremap ;h ====<Space><++><Esc>F=hi
autocmd Filetype markdown,rmd inoremap ;i ![](<++>)<++><Esc>F[a
autocmd Filetype markdown,rmd inoremap ;a [](<++>)<++><Esc>F[a
autocmd Filetype markdown,rmd inoremap ;1 #<Space><Enter><++><Esc>kA
autocmd Filetype markdown,rmd inoremap ;2 ##<Space><Enter><++><Esc>kA
autocmd Filetype markdown,rmd inoremap ;3 ###<Space><Enter><++><Esc>kA
autocmd Filetype markdown,rmd inoremap ;l --------<Enter>
autocmd Filetype markdown map <F5> :!pandoc<space><C-r>%<space>-o<space><C-r>%.pdf<Enter><Enter>
autocmd Filetype r,rmd map <F5> :!echo<space>"require(rmarkdown);<space>render('<c-r>%')"<space>\|<space>R<space>--vanilla<enter>
autocmd Filetype markdown,rmd inoremap ;r ```{r}<CR>```<CR><CR><esc>2kO
autocmd Filetype markdown,rmd inoremap ;p ```{python}<CR>```<CR><CR><esc>2kO
autocmd Filetype r,rmd inoremap ;; %>%<CR>

"" ================================
"" Python
"" ================================
autocmd Filetype python inoremap ;c class<space><++>(<++>):<CR>def<space>__init__(self):<CR>pass
autocmd Filetype python inoremap ;d def<space><++>(<++>):<CR>pass
autocmd Filetype python inoremap ;m if<space>__name__<space>==<space>"__main__":<CR><++>

"" ================================
"" Jupyter
"" ================================
autocmd Filetype ipynb nmap <silent><Leader>b :VimpyterInsertPythonBlock<CR>
"autocmd Filetype ipynb nmap <silent><Leader>j :VimpyterStartJupyter<CR>
"autocmd Filetype ipynb nmap <silent><Leader>n :VimpyterStartNteract<CR>

"" ================================
"" R
"" ================================
autocmd Filetype r,rmd set shiftwidth=2   	" operation >> indents 2 columns; << unindents 2 columns
autocmd Filetype r,rmd set tabstop=2		" a hard TAB displays as 2 columns
autocmd Filetype r,rmd set expandtab		" insert spaces when hitting TABs
autocmd Filetype r,rmd set softtabstop=2	" insert/delete 2 spaces when hitting a TAB/BACKSPACE

"" ================================
"" julia
"" ================================
autocmd Filetype julia set shiftwidth=2   	" operation >> indents 2 columns; << unindents 2 columns
autocmd Filetype julia set tabstop=2		" a hard TAB displays as 2 columns
autocmd Filetype julia set expandtab		" insert spaces when hitting TABs
autocmd Filetype julia set softtabstop=2	" insert/delete 2 spaces when hitting a TAB/BACKSPACE


"" ================================
"" JavaScript
"" ================================
au Filetype javascript setlocal formatprg=prettier " use prettier from npm to format JS
" autocmd BufWritePre *.js :normal gggqG           " format on save


" Replace all is aliased to S.
nnoremap S :%s//g<Left><Left>

" Use urlview to choose and open a url:
:noremap <leader>u :w<Home>silent <End> !urlview<CR>

" Line, word, and character counts with F3:
map <F3> :!wc <C-R>%<CR>
 
" Spellcheck with F6
map <F6> :setlocal spell! spelllang=en_us<CR>
map <F3> :!wc <C-R>%<CR>

" =====
" Gundo 
" =====
" nnoremap <F1> :GundoToggle<CR>
"

" =========
" UltiSnips
" =========
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
let g:UltiSnipsEditSplit="vertical"
let g:UltiSnipsSnippetDirectories=[$HOME.'/.vim/UltiSnips']


let g:ale_fixers = {
\    'javascript': ['prettier'],
\    'css': ['prettier'],
\}

let g:ale_fix_on_save = 1
