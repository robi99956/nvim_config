" Syf ogólny
set nocompatible
set showmatch
set ignorecase
set mouse=v
set hlsearch
set incsearch
set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4
set autoindent
set number
set wildmode=longest,list
set cc=100
filetype plugin indent on
syntax on
set mouse=a
set clipboard=unnamedplus
filetype plugin on
set cursorline
set ttyfast

augroup neovim_terminal
    autocmd!
    " Enter Terminal-mode (insert) automatically
    autocmd TermOpen * startinsert
    " Disables number lines on terminal buffers
    autocmd TermOpen * :set nonumber norelativenumber
    " allows you to use Ctrl-c on terminal window
    autocmd TermOpen * nnoremap <buffer> <C-c> i<C-c>
    " auto insert mode after buffer change
    autocmd BufWinEnter,WinEnter term://* startinsert
augroup END

" Pluginy
call plug#begin("~/.vim/plugged")
 Plug 'ryanoasis/vim-devicons'
 Plug 'vim-airline/vim-airline'
 Plug 'airblade/vim-gitgutter'
 Plug 'sainnhe/everforest'

 Plug 'sheerun/vim-polyglot'
 Plug 'SirVer/ultisnips'
 Plug 'honza/vim-snippets'
 Plug 'scrooloose/nerdtree'
 Plug 'preservim/nerdcommenter'
 Plug 'mhinz/vim-startify'
 Plug 'kien/ctrlp.vim'
 Plug 'neoclide/coc.nvim', {'branch': 'release'}
 Plug 'skywind3000/vim-quickui'
call plug#end()

colorscheme everforest

let g:airline_theme="everforest"
let g:airline_powerline_fonts = 1
let g:airline#extensions#whitespace#enabled = 0

let g:NERDTrimTrailingWhitespace = 1
let g:NERDCommentEmptyLines = 1
let g:NERDCustomDelimiters = { 'c': { 'left': '//','right': '' } }
let g:NERDDefaultAlign = 'start'
let g:NERDComAlignedComment = 1
let g:NERDRemoveExtraSpaces = 0
let g:NERDTreeShowHidden=1

let g:ctrlp_show_hidden = 1

" Guziki
let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<cr>', '<2-LeftMouse>'],
    \ 'AcceptSelection("h")': ['<c-x>', '<c-s>'],
    \ 'AcceptSelection("t")': ['<c-cr>', '<c-t>', '<tab>'],
    \ 'AcceptSelection("v")': ['<c-v>', '<RightMouse>'],
    \ 'PrtExpandDir()':       [],
    \ }

tnoremap <Esc> <C-\><C-n>
tnoremap <C-q> <C-\><C-n> :q!<CR>
nnoremap <C-q> :botright vs <bar> terminal<CR>

nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>
nnoremap <C-j> :tabprevious<CR>
nnoremap <C-k> :tabnext<CR>

nnoremap ,/ :call nerdcommenter#Comment(0,"toggle")<CR>
vnoremap ,/ :call nerdcommenter#Comment(0,"toggle")<CR>

"*** nerdtree
nnoremap <C-e> :NERDTreeToggle<CR>

" Start NERDTree. If a file is specified, move the cursor to its window.
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif

" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
" Open the existing NERDTree on each new tab.
autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif

let NERDTreeCustomOpenArgs={'file':{'where': 'p', 'keepopen': 1, 'stay': 1, 'reuse': 'all'}}

"*** Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" move line or visually selected block - alt+Up/Down
nnoremap <A-Down> :m .+1<CR>==
nnoremap <A-Up> :m .-2<CR>==
inoremap <A-Down> <Esc>:m .+1<CR>==gi
inoremap <A-Up> <Esc>:m .-2<CR>==gi
vnoremap <A-Down> :m '>+1<CR>gv=gv
vnoremap <A-Up> :m '<-2<CR>gv=gv

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" GoTo code navigation
nmap <silent> <C-]> <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

let g:coc_snippet_next = '<Tab>'
let g:coc_snippet_prev = '<S-Tab>'

" Symbol navigation menu
let g:context_menu_k = [
        \ ["Search References\t\\gr", 'call CocAction("jumpReferences")'],
        \ ["Refactor\t", 'call CocAction("refactor")'],
        \ ["Jump to declaration\t\\C-[", 'call CocAction("jumpDeclaration")'],
        \ ["Jump to definition\t\\C-]", 'call CocAction("jumpDefinition")'],
        \ ]

nnoremap <silent>K :call quickui#tools#clever_context('k', g:context_menu_k, {})<cr>
