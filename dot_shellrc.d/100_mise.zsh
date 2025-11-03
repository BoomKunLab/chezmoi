# mise installed by brew on zsh
if [ -f $HOMEBREW_PREFIX/bin/mise ]; then
    eval "$(mise activate zsh)"
    # source <(mise completion zsh)
fi

# mise completion zsh | sudo tee /usr/local/share/zsh/site-functions/_mise
