# mise installed by brew on zsh
if [ -f $HOMEBREW_PREFIX/bin/mise ]; then
    eval "$($HOMEBREW_PREFIX/bin/mise activate zsh)"
fi
