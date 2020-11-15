#!/bin/sh -e

git_clone_or_update() {
  if test -d "${2}"; then
    bash -c "cd \"${2}\" && git pull"
  else
    git clone "${1}" "${2}"
  fi
}

vim_git_clone_or_update() {
  dir="$HOME/.vim/bundle/$(basename -s .git "$1")"
  if test -n "$2"; then
    dir="$HOME/.vim/bundle/$2"
  fi

  git_clone_or_update "$1" "$dir"
}

mkdir -p "$HOME/.vim/autoload/airline/themes" "$HOME/.vim/bundle" "$HOME/.vim/syntax"

# Install Vim plugins
vim_git_clone_or_update "https://github.com/scrooloose/nerdtree.git"
vim_git_clone_or_update "https://github.com/scrooloose/nerdcommenter.git"
vim_git_clone_or_update "https://github.com/scrooloose/syntastic.git"
vim_git_clone_or_update "https://github.com/ervandew/supertab.git"
vim_git_clone_or_update "https://github.com/tpope/vim-rails.git"
vim_git_clone_or_update "https://github.com/tpope/vim-bundler.git"
vim_git_clone_or_update "https://github.com/moll/vim-node.git"
vim_git_clone_or_update "https://github.com/docunext/closetag.vim.git" closetag
vim_git_clone_or_update "https://github.com/maksimr/vim-jsbeautify.git"
vim_git_clone_or_update "https://github.com/terryma/vim-multiple-cursors.git"
vim_git_clone_or_update "https://github.com/mbbill/undotree.git"
vim_git_clone_or_update "https://github.com/mhinz/vim-signify.git"
vim_git_clone_or_update "https://github.com/tpope/vim-fugitive.git"
vim_git_clone_or_update "https://github.com/bling/vim-airline.git"
vim_git_clone_or_update "https://github.com/dyng/ctrlsf.vim.git"
#vim_git_clone_or_update "https://github.com/myusuf3/numbers.vim.git" numbers
vim_git_clone_or_update "https://github.com/powerline/fonts.git" powerline-fonts
vim_git_clone_or_update "https://github.com/vim-airline/vim-airline-themes"
vim_git_clone_or_update "https://github.com/mxw/vim-jsx.git"
vim_git_clone_or_update "https://github.com/leafgarland/typescript-vim.git"
vim_git_clone_or_update "https://github.com/nathanaelkane/vim-indent-guides.git"
vim_git_clone_or_update "https://github.com/kien/rainbow_parentheses.vim.git" rainbow_parentheses
vim_git_clone_or_update "https://github.com/wincent/command-t.git"
vim_git_clone_or_update "https://github.com/derekwyatt/vim-scala"
vim_git_clone_or_update "https://github.com/JuliaEditorSupport/julia-vim.git"

cd "$HOME/.vim/bundle/vim-jsbeautify"
git submodule update --init --recursive
cd -

cd "$HOME/.vim/bundle/powerline-fonts"
./install.sh
cd -

cd "$HOME/.vim/bundle/command-t/ruby/command-t/ext/command-t"
asdf install
asdf exec ruby extconf.rb
make
cd -
