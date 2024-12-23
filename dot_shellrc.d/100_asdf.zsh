# asdf install by git on zsh
if [ -f ~/.asdf/asdf.sh ]; then
    . "$HOME/.asdf/asdf.sh"
fi
if [ -f ~/.asdf/asdf.sh ]; then
    fpath=(${ASDF_DIR}/completions $fpath)
    autoload -Uz compinit && compinit
fi

# asdf install by brew on zsh
if [ -f $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh ]; then
    . "$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh"
fi
