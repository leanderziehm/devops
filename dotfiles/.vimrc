set tabstop=2
set shiftwidth=2

" set tabline=%F%m
" set showtabline=2
"  set number

" Move Lines Like VSCode (Alt + Arrow)
nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
vnoremap <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv
nnoremap <M-Down> :m .+1<CR>==
nnoremap <M-Up> :m .-2<CR>==
vnoremap <M-Down> :m '>+1<CR>gv=gv
vnoremap <M-Up> :m '<-2<CR>gv=gv
inoremap <M-j> <Esc>:m .+1<CR>==gi
inoremap <M-k> <Esc>:m .-2<CR>==gi
inoremap <M-Down> <Esc>:m .+1<CR>==gi
inoremap <M-Up> <Esc>:m .-2<CR>==gi

" TODO: 
" toggle comments with /
" MAYBE:
" ? better markdown support?
" ? better search, show search count and index, wild star lowercase search
" vscode keyboard shortcuts ctrl z,  
" clipboard integration, ctrl v, ctrl c
" vim bookmarks  
" restore cursor postion where it last was 
" color scheme, theme toggle, custom color scheme 
" highlight yanking
" vimwiki
" file exploter
" better splits
" terminal like vscode? nvim or tmux
" keyboard shortcuts help page
" diff viewer
" line folding with alt + z
" omni search like obsidian and or vscode, cntrl p
" go normal model if idle?
" autosave markdown?
" remap leader to space?
" hotreload vim settings?
" https://github.com/leanderziehm/dotfiles/blob/main/other/sync/arch1/.vimrc
"
"
"
"
"

"set termguicolors
"syntax on
"filetype plugin indent on
"set nocompatible
"set mouse=a
"set viminfo='100,<50,s10,h

" =========================================================
" Restore Cursor Position
" =========================================================

"augroup restore_cursor
"  autocmd!
"  autocmd BufReadPost *
"        \ if line("'\"") > 0 && line("'\"") <= line("$") |
"        \ execute "normal! g`\"" |
"        \ endif
"augroup END


" =========================================================
" Search
" =========================================================

set ignorecase
set smartcase
set incsearch
set hlsearch

" =========================================================
" Search
" =========================================================

set ignorecase
set smartcase
set incsearch
set hlsearch

" =========================================================
" Undo / Swap / Backup (Vim compatible)
" =========================================================
let data_dir = expand('~/.vim')

function! EnsureDir(dir)
  if !isdirectory(a:dir)
    call mkdir(a:dir, 'p')
  endif
endfunction

" Undo
let undo_dir = data_dir . '/undo'
call EnsureDir(undo_dir)

set undofile
execute 'set undodir=' . undo_dir

" Swap
let swap_dir = data_dir . '/swap'
call EnsureDir(swap_dir)

execute 'set directory=' . swap_dir

" Backup
let backup_dir = data_dir . '/backup'
call EnsureDir(backup_dir)

set backup
set writebackup

execute 'set backupdir=' . backup_dir

" Better defaults
set undolevels=1000
set undoreload=10000
set backupcopy=yes