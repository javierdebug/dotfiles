let mapleader = " " " map leader to Space key
let g:mapleader = " "
set tabstop=2 softtabstop=2
set shiftwidth=2
set expandtab
set smartindent

set exrc
set relativenumber
set nu
set nohlsearch
set hidden
set nowrap
set incsearch
set scrolloff=8
set colorcolumn=80
let &titlestring = $USER . "@" . hostname() . " " . expand("%:p")
if &term == "screen"
  set t_ts=^[k
  set t_fs=^[\
endif
if &term == "screen" || &term == "xterm"
  set title
endif
"syntax on
set noswapfile


call plug#begin('~/local/share/nvim/plugged')
" Use release branch (recommend)
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'https://github.com/ctrlpvim/ctrlp.vim'
    " Plug 'https://github.com/preservim/nerdtree'
    Plug 'https://github.com/tpope/vim-commentary'
    " Plug 'christoomey/vim-system-copy'
    Plug 'dracula/vim', { 'as': 'dracula' }
    Plug 'EdenEast/nightfox.nvim'
    Plug 'vim-airline/vim-airline'
    Plug 'prettier/vim-prettier', {
      \'do': 'npm install -g prettier',
      \ 'for': [
        \ 'javascript',
        \ 'typescript',
        \ 'css',
        \ 'less',
        \ 'scss',
        \ 'json',
        \ 'graphql',
        \ 'markdown',
        \ 'vue',
        \ 'lua',
        \ 'php',
        \ 'python',
        \ 'html',
        \ 'swift' ] }
    Plug 'jiangmiao/auto-pairs'
    Plug 'tpope/vim-fugitive'
    Plug 'airblade/vim-gitgutter'
    Plug 'Yggdroot/indentLine'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'airblade/vim-rooter'
call plug#end()


" Move 1 more lines up or down in normal and visual selection modes.
nnoremap <C-j> :m .+1<CR>==
nnoremap <C-k> :m .-2<CR>==
inoremap <C-j> <Esc>:m .+1<CR>==gi
inoremap <C-k> <Esc>:m .-2<CR>==gi
vnoremap <C-j> :m '>+1<CR>gv=gv
vnoremap <C-k> :m '<-2<CR>gv=gv
"

"Colorscheme theme:
" colorscheme torte
" colorscheme dracula
colorscheme nightfox

"CtrlP settings: //Not working rn
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
"let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_working_path_mode = ""

"NERDTreeToggle remap:
"nnoremap <silent> <expr> <F6> g:NERDTree.IsOpen() ? "\:NERDTreeClose<CR>" : bufexists(expand('%')) ? "\:NERDTreeFind<CR>" : "\:NERDTreeCWD<CR>"

" run current file (see JS output in console):
nnoremap <Leader>x :w<CR> :!node %<CR>

"Prettier Setup :
" nnoremap <Leader>py :Prettier<CR>
nmap <Leader>y <Plug>(Prettier)
" let g:prettier#autoformat = 1
" autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.svelte,*.yaml,*.html PrettierAsync

" let g:prettier#autoformat_require_pragma = 0
let g:prettier#config#tab_width = 2
" let g:prettier#config#use_tabs = 'true'
let g:prettier#exec_cmd_path = "~/path/to/cli/prettier"

" when running at every change you may want to disable quickfix
" let g:prettier#quickfix_enabled = 0
" autocmd TextChanged,InsertLeave *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.svelte,*.yaml,*.html PrettierAsync

" remaps:
nnoremap <Leader>y "+y
vnoremap <Leader>y "+y
nmap <Leader>Y "+yy

" inoremap <Leader>b <Esc>:Lex<cr>:vertical resize 30<cr>
nnoremap <Leader>M <Esc>:Lex<cr>:vertical resize 30<cr>

"Better way to tab: 
vnoremap < <gv
vnoremap > >gv

source $HOME/.config/nvim/plug-config/coc.vim
source $HOME/.config/nvim/plug-config/fzf.vim
