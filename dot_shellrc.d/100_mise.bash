# mise installed by brew on bash
if [ -f $HOMEBREW_PREFIX/bin/mise ]; then
    eval "$($HOMEBREW_PREFIX/bin/mise activate bash)"
fi
